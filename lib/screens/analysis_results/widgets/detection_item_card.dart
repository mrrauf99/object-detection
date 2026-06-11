import 'package:flutter/material.dart';
import 'package:tensorflow_demo/screens/analysis_results/models/analysis_result.dart';
import 'package:tensorflow_demo/screens/analysis_results/theme/detection_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETECTION ITEM CARD
// ─────────────────────────────────────────────────────────────────────────────

/// Animated card showing a single [DetectedObject].
///
/// Each card:
/// - Fades in and slides up from below using [FadeTransition] + [SlideTransition]
/// - Animates its progress bar from 0 → confidence in 600 ms
/// - Is staggered by `index × 80 ms` relative to its siblings
class DetectionItemCard extends StatefulWidget {
  const DetectionItemCard({
    required this.object,
    required this.index,
    required this.theme,
    super.key,
  });

  final DetectedObject object;

  /// Position in the list — drives the stagger delay.
  final int index;

  final DetectionTheme theme;

  @override
  State<DetectionItemCard> createState() => _DetectionItemCardState();
}

class _DetectionItemCardState extends State<DetectionItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Card opacity: 0 → 1.
  late final Animation<double> _fade;

  /// Card vertical slide: 30 % of its own height → 0.
  late final Animation<Offset> _slide;

  /// Progress bar fill: 0 → confidence.
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: DetectionSizes.animationDurationMs),
    );

    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _fade = curve;

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(curve);

    _progress = Tween<double>(
      begin: 0.0,
      end: widget.object.confidence,
    ).animate(curve);

    // Stagger: each card starts slightly after the previous one.
    final delay =
        Duration(milliseconds: widget.index * DetectionSizes.staggerDelayMs);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _CardBody(
          object: widget.object,
          theme: widget.theme,
          progressAnimation: _progress,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD BODY  (StatelessWidget so the painter rebuilds only for progress)
// ─────────────────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.object,
    required this.theme,
    required this.progressAnimation,
  });

  final DetectedObject object;
  final DetectionTheme theme;
  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    final label = _capitalize(object.label);
    final percent = '${(object.confidence * 100).round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DetectionSizes.cardPaddingV,
        horizontal: DetectionSizes.cardPaddingH,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(DetectionSizes.cardBorderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Label + Progress bar ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Object name
                Text(
                  label,
                  style: TextStyle(
                    fontSize: DetectionSizes.labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: theme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                // Animated progress bar
                _AnimatedProgressBar(
                  animation: progressAnimation,
                  trackColor: theme.progressTrack,
                  fillColor: theme.accent,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Percentage badge ─────────────────────────────────────────────
          _PercentBadge(text: percent, theme: theme),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

/// A 7 px tall pill-shaped bar that animates its fill from 0 to [animation.value].
///
/// Uses [LayoutBuilder] to get the available width so it works correctly inside
/// any parent — no hard-coded pixel widths.
class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.animation,
    required this.trackColor,
    required this.fillColor,
  });

  final Animation<double> animation;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return SizedBox(
              height: DetectionSizes.progressBarHeight,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(DetectionSizes.progressBarRadius),
                child: Stack(
                  children: [
                    // Track (full width)
                    Positioned.fill(
                      child: ColoredBox(color: trackColor),
                    ),
                    // Fill (animated width)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: (maxW * animation.value).clamp(0.0, maxW),
                      child: ColoredBox(color: fillColor),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERCENTAGE BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.text, required this.theme});

  final String text;
  final DetectionTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DetectionSizes.percentBadgePaddingH,
        vertical: DetectionSizes.percentBadgePaddingV,
      ),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(DetectionSizes.percentBadgeRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: DetectionSizes.percentFontSize,
          fontWeight: FontWeight.w700,
          color: theme.badgeText,
        ),
      ),
    );
  }
}
