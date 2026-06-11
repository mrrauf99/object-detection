import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tensorflow_demo/screens/analysis_results/analysis_results_screen.dart';
import 'package:tensorflow_demo/screens/analysis_results/models/analysis_result.dart';
import 'package:tensorflow_demo/screens/analysis_results/theme/detection_theme.dart';
import 'package:tensorflow_demo/services/snackbar_service.dart';
import 'package:tensorflow_demo/services/tensorflow_service.dart';
import 'package:tensorflow_demo/values/app_constants.dart';

class PhotoAnalyzedScreen extends StatefulWidget {
  const PhotoAnalyzedScreen({required this.imageBytes, super.key});

  final Uint8List imageBytes;

  @override
  State<PhotoAnalyzedScreen> createState() => _PhotoAnalyzedScreenState();
}

class _PhotoAnalyzedScreenState extends State<PhotoAnalyzedScreen> {
  AnalysisResult? _analysisResult;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SnackBarService.show('Finding Objects...');
      _analyzeImage();
    });
  }

  void _analyzeImage() {
    Future.delayed(const Duration(milliseconds: 300), () {
      final output = TensorflowService.ssdMobileNet.analyseImage(
        widget.imageBytes,
      );

      final detectedObjects = output.detectedObjects.map((dm) {
        // Model coords are in [0, 300] space. Normalize to [0.0, 1.0].
        return DetectedObject(
          label: dm.label,
          confidence: dm.score.toDouble(),
          boundingBox: Rect.fromLTWH(
            dm.location.left / AppConstants.ssdCompatibleImageWidth,
            dm.location.top / AppConstants.ssdCompatibleImageHeight,
            dm.location.width / AppConstants.ssdCompatibleImageWidth,
            dm.location.height / AppConstants.ssdCompatibleImageHeight,
          ),
        );
      }).toList();

      final result = AnalysisResult(
        imageUrl: '', // not used since we pass imageProvider directly
        detectedObjects: detectedObjects,
      );

      if (!mounted) return;

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
      SnackBarService.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F14),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Analyzing image...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return AnalysisResultsScreen(
      result: _analysisResult,
      imageProvider: MemoryImage(widget.imageBytes),
      theme: const DetectionTheme
          .purple(), // Can swap out for .blue(), .cyan(), etc.
    );
  }
}
