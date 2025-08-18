import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/core/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/views/widgets/handle_permission_cancel.dart';

part 'speech_controller.freezed.dart';
part 'speech_controller.g.dart';

@freezed
class SpeechState with _$SpeechState {
  const factory SpeechState({
    @Default(false) bool isListening,
    @Default(false) bool isAvailable,
    @Default(['I', 'am', 'ved']) List<String> recognizedWords,
    @Default([false, false, false]) List<bool?> wordMarking,
    @Default(false) bool isPlayingAudio,
    @Default(0) int offset,
    required List<String> targetWords,
    String? errorMessage,
  }) = _SpeechState;
}

@Riverpod(keepAlive: true)
class Speech extends _$Speech {
  stt.SpeechToText? _speech;
  final audioPlayer = AudioPlayer();
  late final langProvider = ref.read(langControllerProvider.notifier);

  stt.SpeechToText get _speechInstance {
    _speech ??= stt.SpeechToText();
    return _speech!;
  }

  bool get isPassed => state.wordMarking.isNotEmpty && state.wordMarking.every((mark) => mark == true);

  bool get isFailed => state.wordMarking.contains(false);

  bool get isTestCompleted => isPassed || isFailed;

  @override
  SpeechState build({required List<String> targetWords}) {
    return SpeechState(
      recognizedWords: List.filled(targetWords.length, ''),
      wordMarking: List.filled(targetWords.length, null),
      offset: 0,
      targetWords: targetWords,
    );
  }

  void resetState() {
    state = SpeechState(
      recognizedWords: List.filled(state.targetWords.length, ''),
      wordMarking: List.filled(state.targetWords.length, null),
      offset: 0,
      targetWords: targetWords,
    );

    cancelListening();
    if (audioPlayer.playing) {
      audioPlayer.stop();
    }
  }

  Future<void> initializeRecognizer() async {
    final available = await _speechInstance.initialize(
      onStatus: _handleStatus,
      finalTimeout: const Duration(seconds: 15),
      onError: (error) => _handleError(error.errorMsg.toString()),
    );

    state = state.copyWith(isAvailable: available);
  }

  void _handleStatus(String status) {
    if (status == stt.SpeechToText.doneStatus || status == stt.SpeechToText.notListeningStatus) {
      state = state.copyWith(isListening: false);
    }
  }

  void _handleError(String error) {
    cancelListening();
    state = state.copyWith(errorMessage: error, isListening: false);
  }

  Future<void> startListening(BuildContext context) async {
    if (!state.isAvailable) {
      await initializeRecognizer();
    }

    if (!state.isAvailable && context.mounted) {
      await _showMicPermissionDeniedDialog(context);
      throw Exception('Microphone permission denied');
    }

    try {
      await _speechInstance.listen(
        pauseFor: const Duration(minutes: 1),
        listenFor: const Duration(minutes: 1),
        onResult: _handleResult,
        listenOptions: stt.SpeechListenOptions(partialResults: true, listenMode: stt.ListenMode.dictation),
      );
    } catch (e) {
      developer.log('error: $e');
    }

    state = state.copyWith(isListening: true);
  }

  String _formatWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (state.targetWords.isEmpty) {
      _handleError(AppConstants.kResetStateError);
      return;
    }

    List<String> currRecognizedWords = result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();

    if (currRecognizedWords.isEmpty) {
      state = state.copyWith(offset: state.recognizedWords.where((word) => word.isNotEmpty).toList().length);
      return;
    }

    var newRecognizedWords = List<String>.from(state.recognizedWords);
    var newWordMarking = List<bool?>.from(state.wordMarking);

    for (var i = 0; i < currRecognizedWords.length; i++) {
      if (i + state.offset >= state.targetWords.length) break;
      newRecognizedWords[i + state.offset] = currRecognizedWords[i];
    }

    for (int i = 0; i < newRecognizedWords.where((word) => word.isNotEmpty).length; i++) {
      if (i >= state.targetWords.length) break;
      String formattedTargetWord = _formatWord(state.targetWords[i]);
      String formattedRecognizedWord = _formatWord(newRecognizedWords[i]);
      newWordMarking[i] = formattedTargetWord == formattedRecognizedWord;
    }

    if (newWordMarking.contains(false) || newWordMarking.every((mark) => mark == true)) {
      stopListening();
    }

    if (newWordMarking.every((mark) => mark == true)) {
      ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
    }
    state = state.copyWith(recognizedWords: newRecognizedWords, wordMarking: newWordMarking);
  }

  Future<void> stopListening() async {
    await _speechInstance.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancelListening() async {
    await _speechInstance.cancel();
    state = state.copyWith(isListening: false);
  }

  Future<void> playAudio(String levelId, String id) async {
    if (audioPlayer.playing) {
      await audioPlayer.stop();
      state = state.copyWith(isPlayingAudio: false);
      return;
    }

    final audioFile = PathService.sublevelAsset(levelId, id, AssetType.audio);

    await audioPlayer.setFilePath('${FileService.documentsDirectory.path}$audioFile');

    state = state.copyWith(isPlayingAudio: true);

    await audioPlayer.play().then((_) async {
      state = state.copyWith(isPlayingAudio: false);

      await audioPlayer.stop();
    });
  }

  Future<void> _showMicPermissionDeniedDialog(BuildContext context) async {
    await handlePermissionDenied(
      context,
      choose(
        hindi:
            'माइक्रोफोन की अनुमति नहीं दी गई है। कृपया ऐप सेटिंग्स में जाकर अनुमति दें ताकि आप यह सुविधा इस्तेमाल कर सकें।',
        hinglish:
            'Microphone ki permission deny ho gayi hai. Kripya app settings mein jaakar permission allow karein taaki yeh feature use kar saken',
        lang: ref.read(langControllerProvider),
      ),
      permission: Permission.microphone,
    );
  }
}
