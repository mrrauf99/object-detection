import 'dart:developer';
import 'dart:ui';

import 'package:image/image.dart';
import 'package:tensorflow_demo/models/detected_object/detected_object_dm.dart';
import 'package:tensorflow_demo/values/app_constants.dart';
import 'package:tensorflow_demo/values/typedefs.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Helper for TensorFlow Lite operations.
class TensorflowHelper {
  const TensorflowHelper._();

  /// Default confidence threshold for filtering detections.
  static const double _defaultConfidenceThreshold = 0.6;

  /// IoU threshold for Non-Maximum Suppression.
  static const double _nmsIoUThreshold = 0.5;

  /// Maps raw class indices to label strings.
  static List<String> getClassification({
    required int numberOfDetections,
    required List<int> classes,
    required List<String>? labelList,
  }) {
    final labels = labelList ?? [];
    final actualLabelLength = labels.length - 1;

    final classification = <String>[];

    for (var i = 0; i < numberOfDetections; i++) {
      final classificationLabelIndex = classes[i];
      // SSD MobileNet V1 COCO outputs 0 for 'person', but labels.txt has 'person' at index 1.
      final mappedIndex = classificationLabelIndex + 1;
      final label =
          mappedIndex > actualLabelLength ? '???' : labels[mappedIndex];
      classification.add(label);
    }

    return classification;
  }

  /// Converts normalized bounding box coordinates to [Rect] objects.
  static List<Rect> getLocationsInRect(List<List<num>> locationsRaw) {
    final locations = <Rect>[];
    final locationsRawLength = locationsRaw.length;
    for (var i = 0; i < locationsRawLength; i++) {
      // locations in raw: [yMin, xMin, yMax, xMax]
      final raw = locationsRaw[i];

      // Convert normalized coordinates to pixel values
      final yMin = (raw[0] * AppConstants.ssdCompatibleImageHeight).toDouble();
      final xMin = (raw[1] * AppConstants.ssdCompatibleImageWidth).toDouble();
      final yMax = (raw[2] * AppConstants.ssdCompatibleImageHeight).toDouble();
      final xMax = (raw[3] * AppConstants.ssdCompatibleImageWidth).toDouble();

      locations.add(Rect.fromLTRB(xMin, yMin, xMax, yMax));
    }
    return locations;
  }

  /// Draws a bounding box and label on the [imageInput].
  static void drawOnImage({
    required Image imageInput,
    required Rect rect,
    required num score,
    String? classification,
    Color? color,
  }) {
    final drawColor = color ?? ColorRgb8(255, 255, 255);

    final top = rect.top.toInt();
    final left = rect.left.toInt();

    // Rectangle drawing
    drawRect(
      imageInput,
      x1: left,
      y1: top,
      x2: rect.right.toInt(),
      y2: rect.bottom.toInt(),
      color: drawColor,
      thickness: 3,
    );

    // Label drawing
    if (classification == null) return;
    drawString(
      imageInput,
      '$classification ${(score * 100).toStringAsFixed(0)}%',
      font: arial14,
      x: left + 1,
      y: top + 1,
      color: drawColor,
    );
  }

  /// Computes Intersection over Union (IoU) between two rectangles.
  static double _computeIoU(Rect a, Rect b) {
    final intersect = a.intersect(b);
    if (intersect.isEmpty || intersect.width <= 0 || intersect.height <= 0) {
      return 0.0;
    }
    final intersectionArea = intersect.width * intersect.height;
    final unionArea =
        a.width * a.height + b.width * b.height - intersectionArea;
    if (unionArea <= 0) return 0.0;
    return intersectionArea / unionArea;
  }

  /// Applies Non-Maximum Suppression to filter overlapping detections.
  static List<DetectedObjectDm> _applyNMS(
    List<DetectedObjectDm> detections, {
    double iouThreshold = _nmsIoUThreshold,
  }) {
    if (detections.isEmpty) return detections;

    final selected = <DetectedObjectDm>[];
    final suppressed = List<bool>.filled(detections.length, false);

    for (var i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      selected.add(detections[i]);

      for (var j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        final iou = _computeIoU(
          detections[i].location,
          detections[j].location,
        );
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return selected;
  }

  /// Runs the detection pipeline: preprocess → inference → postprocess.
  static AnalyseImageCallback analyseImage(
    Image image, {
    required Interpreter interpreter,
    required List<String> label,
    int imageRotation = 0,
    bool isFrontCamera = false,
    bool returnDetectedImage = true,
    bool drawObjectOnImage = true,
    double confidenceThreshold = _defaultConfidenceThreshold,
  }) {
    log(
      'analyseImage: inputSize=${image.width}×${image.height}, '
      'rotation=$imageRotation, frontCam=$isFrontCamera',
      name: 'TensorflowHelper',
    );

    // Step 1: Rotate to upright BEFORE resizing.
    // Critical: rotating after resize would place model-output coords in the
    // rotated frame while the screen preview is in upright frame → misaligned boxes.
    Image processedImage = image;
    if (imageRotation != 0) {
      processedImage = copyRotate(processedImage, angle: imageRotation);
    }

    // Step 2: Mirror for front camera so boxes match the mirrored preview.
    if (isFrontCamera) {
      processedImage = flipHorizontal(processedImage);
    }

    // Step 3: Resize to 300×300 for model input.
    final resizedImage = copyResize(
      processedImage,
      width: AppConstants.ssdCompatibleImageWidth,
      height: AppConstants.ssdCompatibleImageHeight,
    );

    log(
      'analyseImage: after processing size=${resizedImage.width}×${resizedImage.height}',
      name: 'TensorflowHelper',
    );

    final generatedOutput = _runInference(resizedImage, interpreter);

    final locationsRaw = generatedOutput[0].first as List<List<num>>;
    final classesRaw = generatedOutput[1].first as List<num>;
    final scores = generatedOutput[2].first as List<num>;
    final numberOfDetectionsRaw = generatedOutput[3].first as double;

    // Location — convert normalized [0,1] coords to 300×300 pixel rects
    final locationsInRect = getLocationsInRect(locationsRaw);

    // Classes — convert to int list
    final classes = [for (final c in classesRaw) c.toInt()];

    // Number of detections
    final numberOfDetections = numberOfDetectionsRaw.toInt();

    // Map class indices to label strings
    final classification = getClassification(
      numberOfDetections: numberOfDetections,
      classes: classes,
      labelList: label,
    );

    // Filter by confidence threshold
    final detectedObjectList = <DetectedObjectDm>[];

    for (var i = 0; i < numberOfDetections; i++) {
      final score = scores[i];
      final detectedObjectName = classification[i];

      // Skip background class and low-confidence detections
      if (score > confidenceThreshold && detectedObjectName != '???') {
        final location = locationsInRect[i];
        log(
          'Raw detection: $detectedObjectName score=${score.toStringAsFixed(2)} '
          'rect=${location.left.toInt()},${location.top.toInt()}'
          '→${location.right.toInt()},${location.bottom.toInt()}',
          name: 'TensorflowHelper',
        );
        detectedObjectList.add(
          DetectedObjectDm(
            label: detectedObjectName,
            score: score,
            location: location,
          ),
        );
      }
    }

    // Sort by score descending (highest confidence first)
    detectedObjectList.sort((a, b) => b.score.compareTo(a.score));

    // Apply Non-Maximum Suppression to remove duplicate overlapping boxes
    final filteredDetections = _applyNMS(detectedObjectList);

    log(
      'analyseImage: ${filteredDetections.length} detections after NMS',
      name: 'TensorflowHelper',
    );

    // Optionally draw bounding boxes on the image
    if (drawObjectOnImage) {
      for (final detection in filteredDetections) {
        drawOnImage(
          classification: detection.label,
          imageInput: resizedImage,
          rect: detection.location,
          score: detection.score,
        );
      }
    }

    final imageOutput = returnDetectedImage
        ? encodeJpg(
            copyResize(
              resizedImage,
              height: processedImage.height,
              width: processedImage.width,
            ),
          )
        : null;

    return (imageBytes: imageOutput, detectedObjects: filteredDetections);
  }

  static final List<List<List<int>>> _imageMatrix = List.generate(
    AppConstants.ssdCompatibleImageHeight,
    (y) => List.generate(
      AppConstants.ssdCompatibleImageWidth,
      (x) => List.filled(3, 0),
    ),
  );

  static final Map<int, List<Object>> _outputBuffer = {
    0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
    1: [List<num>.filled(10, 0)],
    2: [List<num>.filled(10, 0)],
    3: [0.0],
  };

  /// Converts image to tensor and runs inference.
  static List<List<Object>> _runInference(
    Image image,
    Interpreter interpreter,
  ) {
    // Creating matrix representation [300, 300, 3] from the resized image.
    // Reuse the pre-allocated _imageMatrix to prevent 90,000 allocations per frame.
    final height = image.height;
    final width = image.width;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final rgb = _imageMatrix[y][x];
        rgb[0] = pixel.r.toInt().clamp(0, 255);
        rgb[1] = pixel.g.toInt().clamp(0, 255);
        rgb[2] = pixel.b.toInt().clamp(0, 255);
      }
    }

    // Set input tensor [1, 300, 300, 3]
    final input = [_imageMatrix];

    interpreter.runForMultipleInputs([input], _outputBuffer);
    return _outputBuffer.values.toList();
  }
}
