import 'package:flutter/material.dart';
import 'package:tensorflow_demo/screens/analysis_results/models/analysis_result.dart';
import 'package:tensorflow_demo/screens/analysis_results/theme/detection_theme.dart';
import 'package:tensorflow_demo/screens/analysis_results/widgets/detected_objects_list.dart';
import 'package:tensorflow_demo/screens/analysis_results/widgets/image_analysis_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANALYSIS RESULTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

/// Production-ready Analysis Results screen.
///
/// ## Usage
///
/// ```dart
/// // With real data (MemoryImage from camera):
/// AnalysisResultsScreen(
///   result: AnalysisResult(
///     imageUrl: '',          // unused when imageProvider is passed
///     detectedObjects: [...],
///   ),
///   imageProvider: MemoryImage(capturedBytes),
///   theme: const DetectionTheme.purple(),  // or .blue(), .green() …
/// )
///
/// // Preview / development (uses mock data + network image):
/// const AnalysisResultsScreen()
/// ```
class AnalysisResultsScreen extends StatelessWidget {
  const AnalysisResultsScreen({
    this.result,
    this.imageProvider,
    this.theme = const DetectionTheme.purple(),
    super.key,
  });

  /// Detection result to display.  Falls back to [AnalysisResult.mock] if null.
  final AnalysisResult? result;

  /// Optional pre-built image provider.
  /// When omitted, a [NetworkImage] is created from [result.imageUrl].
  final ImageProvider? imageProvider;

  /// Color palette — swap to any of the six variants.
  final DetectionTheme theme;

  @override
  Widget build(BuildContext context) {
    final data = result ?? AnalysisResult.mock;
    final provider = imageProvider ?? NetworkImage(data.imageUrl);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Top: image + bounding boxes ───────────────────────────────────
          ImageAnalysisView(
            imageProvider: provider,
            detectedObjects: data.detectedObjects,
            theme: theme,
          ),

          // ── Bottom: scrollable detection list ─────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: DetectedObjectsList(
                objects: data.detectedObjects,
                theme: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom AppBar ──────────────────────────────────────────────────────────
  //
  // Uses a PreferredSize + Container so we can add a bottom border without
  // relying on the system shadow (elevation: 0).

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.headerBackground,
          border: Border(
            bottom: BorderSide(color: theme.border),
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.darkText),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
          title: Text(
            'Analysis Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.darkText,
            ),
          ),
        ),
      ),
    );
  }
}
