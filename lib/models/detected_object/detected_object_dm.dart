import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:tensorflow_demo/models/screen_params.dart';
import 'package:tensorflow_demo/values/app_constants.dart';

/// Represents the recognition output from the model.
class DetectedObjectDm {
  const DetectedObjectDm({
    required this.label,
    required this.score,
    required this.location,
  });

  /// Label of the result.
  final String label;

  /// Confidence [0.0, 1.0].
  final num score;

  /// Location of bounding box rect in model space (300×300 px, upright).
  ///
  /// Guaranteed to be in upright coordinate space because [TensorflowHelper]
  /// rotates the image before running inference.
  final Rect location;

  /// Returns bounding box rectangle scaled to the displayed preview size.
  ///
  /// Model space (300×300) → screen preview space (screenWidth × previewHeight).
  Rect get renderLocation {
    final previewSize = ScreenParams.screenPreviewSize;
    final double scaleX =
        previewSize.width / AppConstants.ssdCompatibleImageWidth;
    final double scaleY =
        previewSize.height / AppConstants.ssdCompatibleImageHeight;

    final rendered = Rect.fromLTWH(
      location.left * scaleX,
      location.top * scaleY,
      location.width * scaleX,
      location.height * scaleY,
    );

    log(
      '$label: model=${location.left.toInt()},${location.top.toInt()}'
      '→${location.right.toInt()},${location.bottom.toInt()} '
      'scale=$scaleX×$scaleY '
      'screen=${rendered.left.toInt()},${rendered.top.toInt()}'
      '→${rendered.right.toInt()},${rendered.bottom.toInt()}',
      name: 'DetectedObjectDm.renderLocation',
    );

    return rendered;
  }

  @override
  String toString() {
    return 'DetectedObjectDm(label: $label, score: $score, location: $location)';
  }
}
