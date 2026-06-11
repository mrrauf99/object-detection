import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tensorflow_demo/models/detected_object/detected_object_dm.dart';

/// Renders a bounding box with a modern pill-shaped label badge.
///
/// Format: "Laptop • 87%"
///
/// Design goals:
/// - Label is NEVER clipped — uses `IntrinsicWidth` + unconstrained layout.
/// - Glassmorphism badge with semi-transparent backdrop blur.
/// - High-contrast white text on dark background.
/// - Rounded border to visually frame the detected object.
class BoxWidget extends StatelessWidget {
  const BoxWidget({
    required this.label,
    required this.score,
    this.width,
    this.height,
    super.key,
  });

  final double? width;
  final double? height;
  final String label;
  final num score;

  BoxWidget.fromDetectedObject(DetectedObjectDm recognition, {super.key})
      : label = recognition.label,
        score = recognition.score,
        width = recognition.renderLocation.width,
        height = recognition.renderLocation.height;

  String get _formattedScore => '${(score * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bounding box border
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Label badge — positioned above the top-left of the box.
          // Clip.none on the Stack allows this to overflow upward.
          Positioned(
            top: -34,
            left: 0,
            child: _LabelBadge(label: label, score: _formattedScore),
          ),
        ],
      ),
    );
  }
}

/// A self-sizing pill badge displaying "Label • XX%".
class _LabelBadge extends StatelessWidget {
  const _LabelBadge({required this.label, required this.score});

  final String label;
  final String score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Object name — never truncated; badge grows to fit
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Confidence percentage
              Text(
                score,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
