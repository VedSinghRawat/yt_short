import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';
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
    @Default([]) List<String> recognizedWords,
    @Default([]) List<bool?> wordMarking,
    @Default(false) bool isPlayingAudio,
    @Default(0) int offset,
    String? errorMessage,
  }) = _SpeechState;
}

@riverpod
class Speech extends _$Speech {
  late final stt.SpeechToText _speech;
  List<String> _targetWords = [];
  final audioPlayer = AudioPlayer();
  late final langProvider = ref.read(langControllerProvider.notifier);

  @override
  SpeechState build() {
    _speech = stt.SpeechToText();

    ref.onDispose(cancelListening);

    return const SpeechState();
  }

  void setTargetWords(List<String> words) {
    _targetWords = words;
    state = SpeechState(
      recognizedWords: List.filled(words.length, ''),
      wordMarking: List.filled(words.length, null),
      offset: 0,
    );
  }

  Future<void> initialize() async {
    final available = await _speech.initialize(
      onStatus: _handleStatus,
      finalTimeout: const Duration(seconds: 15),
      onError: _handleError,
    );

    state = state.copyWith(isAvailable: available);
  }

  void _handleStatus(String status) {
    if (status == stt.SpeechToText.doneStatus || status == stt.SpeechToText.notListeningStatus) {
      state = state.copyWith(isListening: false);
    }
  }

  void _handleError(dynamic error) {
    state = state.copyWith(errorMessage: error.errorMsg.toString(), isListening: false);
  }

  Future<void> startListening(BuildContext context) async {
    if (!state.isAvailable) {
      await initialize();
    }

    if (!state.isAvailable && context.mounted) {
      await _showMicPermissionDeniedDialog(context);
      throw Exception('Microphone permission denied');
    }

    await _speech.listen(
      pauseFor: const Duration(minutes: 1),
      listenFor: const Duration(minutes: 1),
      onResult: _handleResult,
      listenOptions: stt.SpeechListenOptions(partialResults: true, listenMode: stt.ListenMode.dictation),
    );

    state = state.copyWith(isListening: true);
  }

  String _formatWord(String word) {
    return word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
  }

  void _handleResult(SpeechRecognitionResult result) {
    List<String> currRecognizedWords = result.recognizedWords.split(' ').where((word) => word.isNotEmpty).toList();

    if (currRecognizedWords.isEmpty) {
      state = state.copyWith(offset: state.recognizedWords.where((word) => word.isNotEmpty).toList().length);
      return;
    }

    var newRecognizedWords = List<String>.from(state.recognizedWords);
    var newWordMarking = List<bool?>.from(state.wordMarking);

    for (var i = 0; i < currRecognizedWords.length; i++) {
      if (i + state.offset >= _targetWords.length) break;
      newRecognizedWords[i + state.offset] = currRecognizedWords[i];
    }

    for (int i = 0; i < newRecognizedWords.where((word) => word.isNotEmpty).length; i++) {
      if (i >= _targetWords.length) break;
      String formattedTargetWord = _formatWord(_targetWords[i]);
      String formattedRecognizedWord = _formatWord(newRecognizedWords[i]);
      newWordMarking[i] = formattedTargetWord == formattedRecognizedWord;
    }

    if (newWordMarking.contains(false) || newWordMarking.every((mark) => mark == true)) {
      stopListening();
    }

    state = state.copyWith(recognizedWords: newRecognizedWords, wordMarking: newWordMarking);
  }

  bool get isPassed => state.wordMarking.every((mark) => mark == true);

  bool get isFailed => state.wordMarking.contains(false);

  bool get isTestCompleted => isPassed || isFailed;

  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
    state = state.copyWith(isListening: false);
  }

  Future<void> playAudio(String levelId, String id) async {
    if (audioPlayer.playing) {
      await audioPlayer.stop();
      state = state.copyWith(isPlayingAudio: false);
      return;
    }

    final audioFile = PathService.sublevelAudio(levelId, id);

    await audioPlayer.setFilePath(audioFile);

    state = state.copyWith(isPlayingAudio: true);

    await audioPlayer.play().then((_) async {
      state = state.copyWith(isPlayingAudio: false);

      await audioPlayer.stop();
    });
  }

  void reset() {
    state = SpeechState(
      recognizedWords: List.filled(_targetWords.length, ''),
      wordMarking: List.filled(_targetWords.length, null),
      offset: 0,
    );
  }

  Future<void> _showMicPermissionDeniedDialog(BuildContext context) async {
    await handlePermissionDenied(
      context,
      langProvider.choose(
        hindi:
            'माइक्रोफोन की अनुमति नहीं दी गई है। कृपया ऐप सेटिंग्स में जाकर अनुमति दें ताकि आप यह सुविधा इस्तेमाल कर सकें।',
        hinglish:
            'Microphone ki permission deny ho gayi hai. Kripya app settings mein jaakar permission allow karein taaki yeh feature use kar saken',
      ),
      permission: Permission.microphone,
    );
  }
}
