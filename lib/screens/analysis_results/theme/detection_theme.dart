import 'package:flutter/material.dart';

/// Detection Theme - color configuration
/// All color and dimension tokens for the Analysis Results screen.
class DetectionTheme {
  const DetectionTheme({
    required this.pageBackground,
    required this.accent,
    required this.border,
    required this.darkText,
    required this.surface,
    required this.progressTrack,
  });

  /// Full-page background color.
  final Color pageBackground;

  /// Primary accent — used for bars, badges, fills.
  final Color accent;

  /// Card and header border color.
  final Color border;

  /// Dark body/label text color.
  final Color darkText;

  /// Card surface (always white in all built-in variants).
  final Color surface;

  /// Progress bar track (unfilled portion).
  final Color progressTrack;

  /// Text on accent-colored backgrounds (always white).
  Color get badgeText => const Color(0xFFFFFFFF);

  /// AppBar / header background.
  Color get headerBackground => const Color(0xFFFFFFFF);

  /// Soft purple (default).
  const DetectionTheme.purple()
      : pageBackground = const Color(0xFFF5F3FF),
        accent = const Color(0xFF7C3AED),
        border = const Color(0xFFEDE9FE),
        darkText = const Color(0xFF1A1A2E),
        surface = const Color(0xFFFFFFFF),
        progressTrack = const Color(0xFFEDE9FE);

  /// Cool blue.
  const DetectionTheme.blue()
      : pageBackground = const Color(0xFFEFF6FF),
        accent = const Color(0xFF2563EB),
        border = const Color(0xFFDBEAFE),
        darkText = const Color(0xFF1E3A5F),
        surface = const Color(0xFFFFFFFF),
        progressTrack = const Color(0xFFDBEAFE);

  /// Fresh green.
  const DetectionTheme.green()
      : pageBackground = const Color(0xFFF0FDF4),
        accent = const Color(0xFF16A34A),
        border = const Color(0xFFDCFCE7),
        darkText = const Color(0xFF14532D),
        surface = const Color(0xFFFFFFFF),
        progressTrack = const Color(0xFFDCFCE7);

  /// Vivid pink.
  const DetectionTheme.pink()
      : pageBackground = const Color(0xFFFDF2F8),
        accent = const Color(0xFFDB2777),
        border = const Color(0xFFFCE7F3),
        darkText = const Color(0xFF500724),
        surface = const Color(0xFFFFFFFF),
        progressTrack = const Color(0xFFFCE7F3);

  /// Warm orange.
  const DetectionTheme.orange()
      : pageBackground = const Color(0xFFFFF7ED),
        accent = const Color(0xFFEA580C),
        border = const Color(0xFFFED7AA),
        darkText = const Color(0xFF431407),
        surface = const Color(0xFFFFFFFF),
        progressTrack = const Color(0xFFFED7AA);

  /// Bright cyan.
  const DetectionTheme.cyan()
      : pageBackground = const Color(0xFFECFEFF),
        accent = const Color(0xFF0891B2),
        border = const Color(0xFFCFFAFE),
        darkText = const Color(0xFF083344),
        surface = const Color(0xFFFFFFFF),
        progressTrack = const Color(0xFFCFFAFE);
}

/// All layout dimensions for the Analysis Results screen.
/// All layout dimensions for the Analysis Results screen.
abstract final class DetectionSizes {
  // Image section
  static const double imageHeight = 220.0;
  static const double gradientFadeHeight = 60.0;

  // Bounding box painter
  static const double boxStrokeWidth = 2.0;
  static const double chipLabelRadius = 6.0;
  static const double chipPadH = 6.0;
  static const double chipPadV = 3.0;
  static const double chipFontSize = 11.0;
  static const double chipGap = 2.0;

  // Section header
  static const double accentBarWidth = 3.0;
  static const double accentBarHeight = 16.0;
  static const double accentBarRadius = 2.0;
  static const double sectionTitleFontSize = 15.0;

  // Count badge
  static const double countBadgePaddingH = 10.0;
  static const double countBadgePaddingV = 3.0;
  static const double countBadgeRadius = 20.0;
  static const double countBadgeFontSize = 12.0;

  // Detection cards
  static const double cardBorderRadius = 14.0;
  static const double cardPaddingV = 13.0;
  static const double cardPaddingH = 16.0;
  static const double cardMarginBottom = 8.0;
  static const double labelFontSize = 14.0;

  // Progress bar
  static const double progressBarHeight = 7.0;
  static const double progressBarRadius = 4.0;

  // Percentage badge
  static const double percentBadgePaddingH = 10.0;
  static const double percentBadgePaddingV = 4.0;
  static const double percentBadgeRadius = 8.0;
  static const double percentFontSize = 13.0;

  // Animation
  static const int animationDurationMs = 600;
  static const int staggerDelayMs = 80;

  // Page padding
  static const double pagePaddingH = 16.0;
  static const double pagePaddingTop = 16.0;
  static const double pagePaddingBottom = 24.0;
  static const double headerGap = 12.0;
}
