import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
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

  Future<void> _showMicPermissionDeniedDialog(BuildContext context, WidgetRef ref) async {
    await handlePermissionDenied(
      context,
      ref
          .read(langProvider.notifier)
          .prefLangText(
            const PrefLangText(
              hindi:
                  'माइक्रोफोन की अनुमति नहीं दी गई है। कृपया ऐप सेटिंग्स में जाकर अनुमति दें ताकि आप यह सुविधा इस्तेमाल कर सकें।',
              hinglish:
                  'Microphone ki permission deny ho gayi hai. Kripya app settings mein jaakar permission allow karein taaki yeh feature use kar saken',
            ),
          ),
      permission: Permission.microphone,
    );
  }

  Future<void> startListening(BuildContext context, WidgetRef ref) async {
    bool available = await _speech.initialize(
      onStatus: onStatusChange,
      onError: (error) => {if (onError != null) onError!(error.errorMsg)},
    );

    if (!available && context.mounted) {
      _showMicPermissionDeniedDialog(context, ref);
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
