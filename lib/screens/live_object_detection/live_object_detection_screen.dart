import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tensorflow_demo/models/detected_object/detected_object_dm.dart';
import 'package:tensorflow_demo/models/screen_params.dart';
import 'package:tensorflow_demo/screens/live_object_detection/widgets/rounded_button.dart';
import 'package:tensorflow_demo/services/detector.dart';
import 'package:tensorflow_demo/services/navigation_service.dart';
import 'package:tensorflow_demo/services/tts_service.dart';
import 'package:tensorflow_demo/values/app_routes.dart';
import 'package:tensorflow_demo/widgets/box_widget.dart';

class LiveObjectDetectionScreen extends StatefulWidget {
  const LiveObjectDetectionScreen({super.key});

  @override
  State<LiveObjectDetectionScreen> createState() =>
      _LiveObjectDetectionScreenState();
}

class _LiveObjectDetectionScreenState extends State<LiveObjectDetectionScreen> {
  final _imagePicker = ImagePicker();

  String? message;
  bool _isCapturing = false;
  bool _isPaused = false;

  late final AppLifecycleListener _appLifecycleListener;

  /// List of available cameras
  late List<CameraDescription> cameras;

  int cameraIndex = 0;

  /// Controller
  CameraController? _cameraController;

  /// Object Detector running on a background [Isolate].
  Detector? _detector;

  StreamSubscription? _objectDetectorStream;

  /// Results to draw bounding boxes
  List<DetectedObjectDm>? detectedObjectList;

  /// Labels visible in the previous frame — used to detect newly appeared objects.
  Set<String> _previousLabels = {};

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _init();
        }
      },
      onInactive: _disposeCamera,
    );
    TtsService.instance.initialize();
    _init();
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;

    _detector?.stop();
    _objectDetectorStream?.cancel();
    _detector = null;
    _objectDetectorStream = null;

    if (mounted) setState(() {});
    try {
      await controller?.dispose();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    final controller = _cameraController;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Object Detection')),
      body: controller == null || !controller.value.isInitialized
          ? Center(child: Text(message ?? 'Initializing...'))
          : Column(
              children: [
                AspectRatio(
                  aspectRatio: 1 / controller.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller),
                      if (_isCapturing)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      // Bounding boxes
                      ...?detectedObjectList?.map(
                        (detectedObject) => Positioned.fromRect(
                          rect: detectedObject.renderLocation,
                          child: BoxWidget.fromDetectedObject(detectedObject),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RoundedButton(
                          size: 48,
                          side: BorderSide.none,
                          color: Colors.white.withValues(alpha: 0.3),
                          onTap: _pickImageFromGallery,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/vectors/gallery.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        RoundedButton(
                          padding: const EdgeInsets.all(2),
                          onTap: _takePicture,
                        ),
                        const SizedBox(width: 20),
                        RoundedButton(
                          size: 48,
                          side: BorderSide.none,
                          color: Colors.white.withValues(alpha: 0.3),
                          onTap: _flipCamera,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/vectors/repeate-music.svg',
                              width: 28,
                              height: 28,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _cameraController?.dispose();
    _objectDetectorStream?.cancel();
    _detector?.stop();
    TtsService.instance.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (_cameraController != null) {
      await _disposeCamera();
    }

    await _initializeCamera();
    await _initializeDetector();

    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    /// Listen each frame from calling the image stream
    if (_cameraController != null &&
        !_cameraController!.value.isStreamingImages) {
      await _cameraController
          ?.startImageStream(onLatestImageAvailable)
          .catchError((_) {});
    }

    /// previewSize is size of each image frame captured by controller
    final size = _cameraController?.value.previewSize;
    if (size != null) {
      ScreenParams.previewSize = size;
      log(
        'Camera preview size: ${size.width}×${size.height}',
        name: 'LiveDetection',
      );
    }

    if (mounted) setState(() {});
  }

  /// Initializes the camera by setting [_cameraController].
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      message = 'No Camera Available';
      if (mounted) setState(() {});
      log('No Camera Available', name: 'LiveDetection');
      return;
    }
    // cameras[0] for back-camera
    cameraIndex = 0;
    _updateScreenParamsForCamera(cameraIndex);

    final camera = cameras[cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController?.initialize();
    await _cameraController?.setFlashMode(FlashMode.off);
  }

  Future<void> _initializeDetector() async {
    if (_detector != null) return;
    final detector = await Detector.start();
    setState(() {
      _detector = detector;
      _objectDetectorStream = detector.resultsStream.listen((detectedObjects) {
        if (!mounted) return;

        // TTS: announce any objects that are new in this frame.
        final currentLabels = detectedObjects.map((o) => o.label).toSet();
        TtsService.instance.announceNewObjects(
          currentLabels: currentLabels,
          previousLabels: _previousLabels,
        );
        _previousLabels = currentLabels;

        log(
          'Detected: ${detectedObjects.map((o) => '${o.label}(${(o.score * 100).toStringAsFixed(0)}%)').join(', ')}',
          name: 'LiveDetection',
        );

        setState(() => detectedObjectList = detectedObjects);
      });
    });
  }

  Future<void> _flipCamera() async {
    if (cameras.length <= 1) return;
    final newIndex = cameraIndex == 1 ? 0 : 1;
    cameraIndex = newIndex;
    _updateScreenParamsForCamera(newIndex);
    _isPaused = true;

    // Stop the image stream BEFORE disposing — prevents "Surface abandoned" errors
    // that occur when the new controller tries to claim the SurfaceTexture while
    // the old one is still releasing it.
    try {
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController?.stopImageStream();
      }
    } catch (_) {}

    // Fully await disposal so the SurfaceTexture is completely freed.
    final oldController = _cameraController;
    _cameraController = null;
    if (mounted) setState(() {});
    try {
      await oldController?.dispose();
    } catch (_) {}

    if (!mounted) return;

    // Small delay to allow hardware to completely release the surface
    // before we try to claim it again (fixes 'Surface was abandoned' crash).
    await Future.delayed(const Duration(milliseconds: 300));

    // Now it is safe to create and initialize the new controller.
    final newController = CameraController(
      cameras[newIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _cameraController = newController;

    try {
      await newController.initialize();
      if (!mounted) return;
      await newController.setFlashMode(FlashMode.off);
      await newController.startImageStream(onLatestImageAvailable);
      final size = newController.value.previewSize;
      if (size != null) {
        ScreenParams.previewSize = size;
        log(
          'Camera flipped. preview size: ${size.width}×${size.height}',
          name: 'LiveDetection',
        );
      }
    } catch (e) {
      log('Error initializing flipped camera: $e', name: 'LiveDetection');
    }

    if (mounted) {
      _isPaused = false;
      setState(() {});
    }
  }

  /// Updates [ScreenParams] to reflect the active camera's orientation/type.
  void _updateScreenParamsForCamera(int index) {
    if (cameras.isEmpty || index >= cameras.length) return;
    final camera = cameras[index];
    ScreenParams.sensorOrientation = camera.sensorOrientation;
    ScreenParams.isFrontCamera =
        camera.lensDirection == CameraLensDirection.front;
    log(
      'Camera[$index]: direction=${camera.lensDirection}, '
      'sensorOrientation=${camera.sensorOrientation}',
      name: 'LiveDetection',
    );
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final capturedImage = await _cameraController?.takePicture();
      final decodedImage = await capturedImage?.readAsBytes();
      if (mounted) {
        setState(() => _isCapturing = false);

        await _disposeCamera();

        await NavigationService.instance.pushNamed(
          AppRoutes.photoAnalyzedScreen,
          arguments: decodedImage,
        );

        if (mounted) {
          _isPaused = false;
          if (_cameraController == null ||
              !_cameraController!.value.isInitialized) {
            _init();
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
      log('Error capturing picture: $e', name: 'LiveDetection');
    }
  }

  Future<void> _pickImageFromGallery() async {
    _isPaused = true;
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    final readAsBytesSync = await result?.readAsBytes();

    if (readAsBytesSync != null) {
      await _disposeCamera();
      await NavigationService.instance.pushNamed(
        AppRoutes.photoAnalyzedScreen,
        arguments: readAsBytesSync,
      );
    }

    if (mounted) {
      _isPaused = false;
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _init();
      }
    }
  }

  /// Callback to receive each frame [CameraImage] and perform inference on it.
  void onLatestImageAvailable(CameraImage cameraImage) {
    if (cameras.isEmpty || _isPaused) return;
    final int rotation = cameras[cameraIndex].sensorOrientation;
    final bool frontCam =
        cameras[cameraIndex].lensDirection == CameraLensDirection.front;
    _detector?.processFrame(
      cameraImage,
      rotation,
      isFrontCamera: frontCam,
    );
  }
}
