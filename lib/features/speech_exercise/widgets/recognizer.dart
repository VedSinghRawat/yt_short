import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognizer {
  final Function(SpeechRecognitionResult) onResult;
  final VoidCallback? onStopListenting;
  final Function(String)? onError;
  final Function(String) onStatusChange;

  late stt.SpeechToText _speech;

  SpeechRecognizer({
    required this.onStatusChange,
    required this.onResult,
    this.onError,
    this.onStopListenting,
  }) {
    _speech = stt.SpeechToText();
  }

  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: onStatusChange,
      onError: (error) => {if (onError != null) onError!(error.errorMsg)},
    );

    if (available) {
      _speech.listen(
        pauseFor: const Duration(minutes: 1),
        listenFor: const Duration(minutes: 1),
        onResult: onResult,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } else {
      if (onError != null) onError!('Speech recognition is not available!');
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    try {
      if (onStopListenting != null) onStopListenting!();
    } catch (e) {
      developer.log('error in speech exercise widget $e');
    }
  }
}
