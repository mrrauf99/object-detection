import 'package:flutter/material.dart';

/// A polished card displaying a detected object's name and confidence percentage.
///
/// Format: object icon + "Laptop" on left, "87%" chip on right.
class DetectedObjectTile extends StatelessWidget {
  const DetectedObjectTile({
    required this.label,
    required this.score,
    super.key,
  });

  final String label;
  final num score;

  String get _formattedScore => '${(score * 100).toStringAsFixed(0)}%';

  // Confidence bar color: green above 75%, amber above 50%, red below.
  Color get _confidenceColor {
    final pct = score.toDouble();
    if (pct >= 0.75) return const Color(0xFF4CAF50);
    if (pct >= 0.50) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Object icon circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _confidenceColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.crop_free_rounded,
              color: _confidenceColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capitalize(label),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Confidence progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.toDouble().clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Confidence percentage chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _confidenceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _confidenceColor.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              _formattedScore,
              style: TextStyle(
                color: _confidenceColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
