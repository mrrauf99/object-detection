import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tensorflow_demo/models/detected_object/detected_object_dm.dart';
import 'package:tensorflow_demo/services/tensorflow_service.dart';
import 'package:tensorflow_demo/utils/image_utils.dart';
import 'package:tensorflow_demo/utils/tensorflow_helper.dart';
import 'package:tensorflow_demo/values/enumerations.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// A command sent between [Detector] and [_DetectorServer].
class _Command {
  const _Command(this.processType, {this.args});

  final TensorflowProcessType processType;
  final List<Object>? args;
}

/// A Simple Detector that handles object detection via Service
///
/// All the heavy operations like pre-processing, detection, etc.
/// are executed in a background isolate.
/// This class just sends and receives messages to the isolate.
class Detector {
  Detector._(this._isolate, this._interpreter, this._labels);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final List<String> _labels;

  // To be used by detector (from UI) to send message to our Service ReceivePort
  late final SendPort _sendPort;

  bool _isReady = false;

  /// Minimum milliseconds between frames sent to isolate (frame throttle).
  static const int _minFrameIntervalMs = 100;
  int _lastFrameSentAt = 0;

  final StreamController<List<DetectedObjectDm>> _resultsStreamController =
      StreamController<List<DetectedObjectDm>>();

  Stream<List<DetectedObjectDm>> get resultsStream =>
      _resultsStreamController.stream;

  /// Launch the server on a background isolate.
  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();
    // sendPort - To be used by service Isolate to send message to our ReceiverPort
    final Isolate isolate =
        await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(
      isolate,
      TensorflowService.ssdMobileNet.interpreter,
      TensorflowService.ssdMobileNet.labels,
    );
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  /// Starts CameraImage processing.
  ///
  /// [imageRotation] — sensor orientation in degrees.
  /// [isFrontCamera] — if true, the image will be horizontally flipped before
  ///   inference so bounding boxes match the mirrored preview.
  void processFrame(
    CameraImage cameraImage,
    int imageRotation, {
    bool isFrontCamera = false,
  }) {
    if (!_isReady) return;

    // Frame throttle: skip if a frame was sent too recently.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFrameSentAt < _minFrameIntervalMs) return;
    _lastFrameSentAt = now;

    _sendPort.send(
      _Command(TensorflowProcessType.detect,
          args: [cameraImage, imageRotation, isFrontCamera]),
    );
  }

  /// Handler invoked when a message is received from the port communicating
  /// with the background isolate.
  void _handleCommand(_Command command) {
    switch (command.processType) {
      case TensorflowProcessType.init:
        _sendPort = command.args?[0] as SendPort;
        // Before using platform channels from background isolates we need to
        // register with the root isolate via [RootIsolateToken].
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(TensorflowProcessType.init, args: [
          rootIsolateToken,
          _interpreter.address,
          _labels,
        ]));
      case TensorflowProcessType.ready:
        _isReady = true;
      case TensorflowProcessType.busy:
        _isReady = false;
      case TensorflowProcessType.result:
        _isReady = true;
        if (!_resultsStreamController.isClosed) {
          _resultsStreamController.add(
            command.args?[0] as List<DetectedObjectDm>,
          );
        }
      default:
        debugPrint('Detector unrecognized command: ${command.processType}');
    }
  }

  /// Kills the background isolate and its detector server.
  void stop() {
    _resultsStreamController.close();
    _isolate.kill();
  }
}

/// The portion of the [Detector] that runs on the background isolate.
///
/// This is where we use Background Isolate Channels, which allows us to use
/// plugins from background isolates.
class _DetectorServer {
  _DetectorServer(this._sendPort);

  Interpreter? _interpreter;
  List<String>? _labels;
  final SendPort _sendPort;

  /// The main entrypoint for the background isolate sent to [Isolate.spawn].
  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    // receivePort.sendPort - used by UI isolate to send commands to the service receiverPort
    sendPort.send(
        _Command(TensorflowProcessType.init, args: [receivePort.sendPort]));
  }

  /// Handle the [command] received from the [ReceivePort].
  Future<void> _handleCommand(_Command command) async {
    switch (command.processType) {
      case TensorflowProcessType.init:
        RootIsolateToken rootIsolateToken =
            command.args?[0] as RootIsolateToken;
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _labels = command.args?[2] as List<String>;
        _sendPort.send(const _Command(TensorflowProcessType.ready));
      case TensorflowProcessType.detect:
        _sendPort.send(const _Command(TensorflowProcessType.busy));
        _convertCameraImage(
          command.args?[0] as CameraImage,
          command.args?[1] as int,
          isFrontCamera: command.args?[2] as bool? ?? false,
        );
      default:
        debugPrint(
            '_DetectorService unrecognized command ${command.processType}');
    }
  }

  /// Convert Camera Image to Image and run detection.
  void _convertCameraImage(
    CameraImage cameraImage,
    int rotation, {
    bool isFrontCamera = false,
  }) {
    final image = ImageUtils.convertCameraImageToImage(cameraImage);
    if (image == null) return;
    final results =
        _analyseImageCamera(image, rotation, isFrontCamera: isFrontCamera);
    _sendPort.send(_Command(TensorflowProcessType.result, args: [results]));
  }

  List<DetectedObjectDm> _analyseImageCamera(
    Image image,
    int rotation, {
    bool isFrontCamera = false,
  }) {
    if (_interpreter == null) return [];
    return TensorflowHelper.analyseImage(
      image,
      interpreter: _interpreter!,
      label: _labels ?? [],
      imageRotation: rotation,
      isFrontCamera: isFrontCamera,
      drawObjectOnImage: false,
      returnDetectedImage: false,
    ).detectedObjects;
  }
}
