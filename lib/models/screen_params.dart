import 'dart:math';
import 'dart:ui';

/// Singleton that records size-related data needed to map model-space
/// bounding boxes onto the screen preview.
class ScreenParams {
  // Default to zero; set during camera initialization.
  static Size screenSize = Size.zero;

  /// Raw preview dimensions as reported by the camera controller.
  /// On Android this is typically landscape (e.g. 1280×720).
  /// On iOS this may be portrait-native.
  static Size? previewSize;

  /// The sensor orientation of the active camera in degrees (0, 90, 180, 270).
  static int sensorOrientation = 0;

  /// Whether the active camera is the front (selfie) camera.
  static bool isFrontCamera = false;

  /// The aspect ratio of the visible camera preview as rendered on screen.
  ///
  /// When [sensorOrientation] is 90° or 270° (most Android devices, back camera),
  /// the physical sensor is landscape but the preview renders in portrait —
  /// so width and height are swapped when computing the ratio.
  static double get previewRatio {
    final size = previewSize;
    if (size == null) return 1;

    final height = size.height;
    final width = size.width;
    // On Android the sensor delivers landscape frames (width > height).
    // The Flutter camera plugin auto-rotates the preview so it appears
    // portrait on screen, meaning the displayed ratio is height/width of sensor.
    final maxValue = max(height, width);
    final minValue = min(height, width);
    return maxValue / minValue;
  }

  /// The pixel dimensions of the camera preview as it appears on screen.
  ///
  /// Width = screen width; Height = width × previewRatio (portrait display).
  static Size get screenPreviewSize =>
      Size(screenSize.width, screenSize.width * previewRatio);
}
