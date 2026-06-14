import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// A single detected object returned by the model.
class DetectedObject {
  const DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  /// Class name, e.g. "Person", "Laptop".
  final String label;

  /// Confidence score in the range [0.0, 1.0].
  final double confidence;

  /// Bounding box in **normalized** coordinates (0.0–1.0) relative to the
  /// displayed image size.  Use [Rect.fromLTWH] with fractional values.
  final Rect boundingBox;
}

/// The complete result of analysing a single image.
class AnalysisResult {
  const AnalysisResult({
    required this.imageUrl,
    required this.detectedObjects,
  });

  /// Remote URL, local file path, or asset key for the source image.
  final String imageUrl;

  /// All objects found in the image, sorted by confidence descending.
  final List<DetectedObject> detectedObjects;

  // ── Mock / preview data ──────────────────────────────────────────────────

  static const AnalysisResult mock = AnalysisResult(
    imageUrl: 'https://picsum.photos/400/220',
    detectedObjects: [
      DetectedObject(
          label: 'Person',
          confidence: 0.75,
          boundingBox: Rect.fromLTWH(0.05, 0.1, 0.20, 0.80)),
      DetectedObject(
          label: 'Person',
          confidence: 0.74,
          boundingBox: Rect.fromLTWH(0.22, 0.15, 0.18, 0.75)),
      DetectedObject(
          label: 'Person',
          confidence: 0.73,
          boundingBox: Rect.fromLTWH(0.38, 0.12, 0.20, 0.78)),
      DetectedObject(
          label: 'Person',
          confidence: 0.71,
          boundingBox: Rect.fromLTWH(0.55, 0.10, 0.19, 0.80)),
      DetectedObject(
          label: 'Person',
          confidence: 0.64,
          boundingBox: Rect.fromLTWH(0.72, 0.14, 0.18, 0.76)),
      DetectedObject(
          label: 'Person',
          confidence: 0.62,
          boundingBox: Rect.fromLTWH(0.88, 0.18, 0.10, 0.70)),
    ],
  );
}
