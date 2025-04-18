import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/handle_permission_cancel.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _showMicPermissionDeniedDialog(BuildContext context) async {
    await handlePermissionDenied(
      context,
      'Microphone permission is denied. Please open app settings and grant permission to use this feature.',
      permission: Permission.microphone,
    );
  }

  Future<void> startListening(BuildContext context) async {
    bool available = await _speech.initialize(
      onStatus: onStatusChange,
      onError: (error) => {if (onError != null) onError!(error.errorMsg)},
    );

    if (!available && context.mounted) {
      _showMicPermissionDeniedDialog(context);
      return;
    }

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
