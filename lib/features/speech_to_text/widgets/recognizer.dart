import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognizer {
  final Function(SpeechRecognitionResult) onResult;
  final VoidCallback? onStopListenting;
  final Function(String)? onError;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  SpeechRecognizer({
    required this.onResult,
    this.onError,
    this.onStopListenting,
  }) {
    _speech = stt.SpeechToText();
  }

  bool get isListening => _isListening;

  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: _onStatus,
      onError: (error) => {if (onError != null) onError!(error.errorMsg)},
    );

    if (available) {
      _isListening = true;
      _speech.listen(
        pauseFor: const Duration(minutes: 1),
        listenFor: const Duration(minutes: 1),
        onResult: onResult,
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    } else {
      _isListening = false;
      if (onError != null) onError!('Speech recognition is not available!');
    }
  }

  void stopListening() {
    _speech.stop();
    if (onStopListenting != null) onStopListenting!();
    _isListening = false;
  }

  void _onStatus(String status) {
    if (status == stt.SpeechToText.doneStatus && _isListening) {
      _speech.listen(
        onResult: onResult,
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    }
  }
}
