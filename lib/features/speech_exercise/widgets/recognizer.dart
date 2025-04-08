import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognizer {
  final Function(SpeechRecognitionResult) onResult;
  final VoidCallback? onStopListening;
  final Function(String)? onError;
  final Function(String) onStatusChange;

  late stt.SpeechToText _speech;

  SpeechRecognizer({
    required this.onStatusChange,
    required this.onResult,
    this.onError,
    this.onStopListening,
  }) {
    _speech = stt.SpeechToText();
  }

  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: onStatusChange,
      onError: (error) => {if (onError != null) onError!(error.errorMsg)},
    );

    if (!available) throw Exception('Speech recognition is not available!');

    _speech.listen(
      pauseFor: const Duration(minutes: 1),
      listenFor: const Duration(minutes: 1),
      onResult: onResult,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    try {
      if (onStopListening != null) onStopListening!();
    } catch (e) {
      developer.log('error in speech exercise widget $e');
    }
  }
}
