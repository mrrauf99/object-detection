import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter_tts/flutter_tts.dart';

/// A singleton service that manages Text-to-Speech announcements for
/// detected objects.
///
/// Features:
/// - Announces each object label in English exactly once per appearance.
/// - Cooldown map: prevents re-announcing the same label within [_cooldownMs].
/// - Queue: serialises multiple simultaneous announcements.
/// - Thread-safe disposal.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  final Queue<String> _queue = Queue<String>();

  /// Tracks the last time (epoch ms) each label was spoken.
  final Map<String, int> _lastSpokenAt = {};

  /// Minimum milliseconds between re-announcements of the same label.
  static const int _cooldownMs = 4000;

  bool _isSpeaking = false;
  bool _isDisposed = false;

  /// Initialises the TTS engine. Call once at app/screen startup.
  Future<void> initialize() async {
    _isDisposed = false;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.55);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _processQueue();
    });

    _tts.setErrorHandler((message) {
      log('TTS error: $message', name: 'TtsService');
      _isSpeaking = false;
      _processQueue();
    });

    log('TtsService initialized', name: 'TtsService');
  }

  /// Announces [label] if:
  /// 1. It has not been spoken recently (cooldown has elapsed), AND
  /// 2. It is not already queued.
  void announce(String label) {
    if (_isDisposed) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSpoken = _lastSpokenAt[label] ?? 0;

    if (now - lastSpoken < _cooldownMs) return; // within cooldown window
    if (_queue.contains(label)) return; // already queued

    _lastSpokenAt[label] = now;
    _queue.add(label);
    _processQueue();
  }

  /// Announces a batch of currently detected labels.
  ///
  /// Only labels that were NOT in [previousLabels] (newly appeared) will
  /// be announced. Pass an empty set on first call.
  void announceNewObjects({
    required Set<String> currentLabels,
    required Set<String> previousLabels,
  }) {
    final newLabels = currentLabels.difference(previousLabels);
    for (final label in newLabels) {
      announce(label);
    }
  }

  void _processQueue() {
    if (_isSpeaking || _queue.isEmpty || _isDisposed) return;
    final label = _queue.removeFirst();
    _isSpeaking = true;
    _tts.speak(label).catchError((e) {
      log('TTS speak error: $e', name: 'TtsService');
      _isSpeaking = false;
      _processQueue();
    });
    log('TTS speaking: "$label"', name: 'TtsService');
  }

  /// Clears the queue and stops any ongoing speech.
  Future<void> stop() async {
    _queue.clear();
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Fully disposes the TTS engine. Call in [State.dispose].
  Future<void> dispose() async {
    _isDisposed = true;
    await stop();
    _lastSpokenAt.clear();
    log('TtsService disposed', name: 'TtsService');
  }
}
