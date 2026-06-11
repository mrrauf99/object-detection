import 'package:flutter/material.dart';
import 'package:tensorflow_demo/screens/analysis_results/models/analysis_result.dart';
import 'package:tensorflow_demo/screens/analysis_results/theme/detection_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE ANALYSIS VIEW
// ─────────────────────────────────────────────────────────────────────────────

/// Fixed-height image panel with bounding-box overlay and a bottom gradient
/// fade that blends into [theme.pageBackground].
///
/// The [imageProvider] can be any Flutter [ImageProvider]:
///   - `NetworkImage(url)` for remote images
///   - `MemoryImage(bytes)` for camera captures
///   - `FileImage(file)` for gallery picks
///   - `AssetImage(path)` for bundled assets
class ImageAnalysisView extends StatelessWidget {
  const ImageAnalysisView({
    required this.imageProvider,
    required this.detectedObjects,
    required this.theme,
    super.key,
  });

  final ImageProvider imageProvider;
  final List<DetectedObject> detectedObjects;
  final DetectionTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DetectionSizes.imageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Base image ────────────────────────────────────────────────────
          Image(
            image: imageProvider,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: theme.border,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: theme.accent,
                  size: 48,
                ),
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(
                color: theme.border,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    color: theme.accent,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),

          // ── Bounding box overlay ──────────────────────────────────────────
          CustomPaint(
            painter: _BoundingBoxPainter(objects: detectedObjects),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOUNDING BOX PAINTER
// ─────────────────────────────────────────────────────────────────────────────

/// [CustomPainter] that draws detection boxes and label chips over the image.
///
/// [DetectedObject.boundingBox] values are in the range [0.0, 1.0] and are
/// scaled to the rendered canvas size, so the painter works at any resolution.
class _BoundingBoxPainter extends CustomPainter {
  const _BoundingBoxPainter({required this.objects});

  final List<DetectedObject> objects;

  static final _boxPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = DetectionSizes.boxStrokeWidth;

  static final _chipBgPaint = Paint()
    ..color = const Color(0xCC000000); // 80 % opaque black

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      // Scale normalized box coords to pixel coords.
      final box = obj.boundingBox;
      final rect = Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      );

      // White stroke rectangle.
      canvas.drawRect(rect, _boxPaint);

      // Label chip above (or below if no room).
      _drawChip(
        canvas,
        size,
        rect,
        '${_capitalize(obj.label)} • ${(obj.confidence * 100).round()}%',
      );
    }
  }

  /// Draws a dark rounded chip with white text above [boxRect].
  void _drawChip(Canvas canvas, Size size, Rect boxRect, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: DetectionSizes.chipFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    const padH = DetectionSizes.chipPadH;
    const padV = DetectionSizes.chipPadV;
    final chipW = textPainter.width + padH * 2;
    final chipH = textPainter.height + padV * 2;

    // Prefer above the box; flip below if clipped at top.
    double chipTop = boxRect.top - chipH - DetectionSizes.chipGap;
    if (chipTop < 0) chipTop = boxRect.top + DetectionSizes.chipGap;

    // Clamp horizontal position inside canvas.
    double chipLeft =
        boxRect.left.clamp(0.0, (size.width - chipW).clamp(0.0, size.width));

    final chipRRect = RRect.fromLTRBR(
      chipLeft,
      chipTop,
      chipLeft + chipW,
      chipTop + chipH,
      const Radius.circular(DetectionSizes.chipLabelRadius),
    );

    canvas.drawRRect(chipRRect, _chipBgPaint);
    textPainter.paint(canvas, Offset(chipLeft + padH, chipTop + padV));
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  @override
  bool shouldRepaint(_BoundingBoxPainter old) => old.objects != objects;
}
