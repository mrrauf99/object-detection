import 'package:flutter/material.dart';
import 'package:tensorflow_demo/screens/analysis_results/models/analysis_result.dart';
import 'package:tensorflow_demo/screens/analysis_results/theme/detection_theme.dart';
import 'package:tensorflow_demo/screens/analysis_results/widgets/detection_item_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETECTED OBJECTS LIST
// ─────────────────────────────────────────────────────────────────────────────

/// Section below the image: header row + one [DetectionItemCard] per object.
class DetectedObjectsList extends StatelessWidget {
  const DetectedObjectsList({
    required this.objects,
    required this.theme,
    super.key,
  });

  final List<DetectedObject> objects;
  final DetectionTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DetectionSizes.pagePaddingH,
        DetectionSizes.pagePaddingTop,
        DetectionSizes.pagePaddingH,
        DetectionSizes.pagePaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────────────
          _SectionHeader(count: objects.length, theme: theme),

          const SizedBox(height: DetectionSizes.headerGap),

          // ── Detection cards ───────────────────────────────────────────────
          if (objects.isEmpty)
            _EmptyState(theme: theme)
          else
            ...objects.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: DetectionSizes.cardMarginBottom),
                    child: DetectionItemCard(
                      object: entry.value,
                      index: entry.key,
                      theme: theme,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count, required this.theme});

  final int count;
  final DetectionTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left accent bar
        Container(
          width: DetectionSizes.accentBarWidth,
          height: DetectionSizes.accentBarHeight,
          decoration: BoxDecoration(
            color: theme.accent,
            borderRadius: BorderRadius.circular(DetectionSizes.accentBarRadius),
          ),
        ),
        const SizedBox(width: 8),
        // Section title
        Text(
          'Detected Objects',
          style: TextStyle(
            fontSize: DetectionSizes.sectionTitleFontSize,
            fontWeight: FontWeight.w500,
            color: theme.darkText,
          ),
        ),
        const Spacer(),
        // Count badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DetectionSizes.countBadgePaddingH,
            vertical: DetectionSizes.countBadgePaddingV,
          ),
          decoration: BoxDecoration(
            color: theme.accent,
            borderRadius:
                BorderRadius.circular(DetectionSizes.countBadgeRadius),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: DetectionSizes.countBadgeFontSize,
              fontWeight: FontWeight.w600,
              color: theme.badgeText,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final DetectionTheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No objects detected',
              style: TextStyle(
                color: theme.darkText.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
