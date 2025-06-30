import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/dialogues/dialogues.dart';
import 'package:myapp/services/dialogue/dialogue_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dialogue_controller.freezed.dart';
part 'dialogue_controller.g.dart';

@freezed
class DialogueControllerState with _$DialogueControllerState {
  const DialogueControllerState._();

  const factory DialogueControllerState({
    @Default({}) Map<String, Dialogue> dialogues,
    @Default({}) Map<String, bool> loadingByDialogueId,
    @Default({}) Map<String, bool> downloadingByZipNum,
    String? error,
  }) = _DialogueControllerState;
}

@Riverpod(keepAlive: true)
class DialogueController extends _$DialogueController {
  late final DialogueService dialogueService = ref.watch(dialogueServiceProvider);

  @override
  DialogueControllerState build() => const DialogueControllerState();

  Future<Dialogue?> get(String id) async {
    state = state.copyWith(
      loadingByDialogueId: {...state.loadingByDialogueId}..update(id, (value) => true, ifAbsent: () => true),
    );

    final dialogueEither = await dialogueService.get(id);

    final dialogue = dialogueEither.fold<Dialogue?>(
      (error) {
        final lang = ref.read(langControllerProvider);
        final message = parseError(error.dioExceptionType, lang);
        state = state.copyWith(error: 'Failed to get dialogue $id: $message');
        return null;
      },
      (dialogueDTO) {
        final dialogue = Dialogue.fromDTO(dialogueDTO, id);
        state = state.copyWith(
          dialogues: {...state.dialogues}..update(id, (value) => dialogue, ifAbsent: () => dialogue),
          error: null,
        );
        return dialogue;
      },
    );

    state = state.copyWith(loadingByDialogueId: {...state.loadingByDialogueId}..update(id, (value) => false));

    return dialogue;
  }

  Future<void> downloadData(int zipNum) async {
    state = state.copyWith(
      downloadingByZipNum: {...state.downloadingByZipNum}
        ..update(zipNum.toString(), (value) => true, ifAbsent: () => true),
    );

    final result = await dialogueService.downloadDialogueZip(zipNum);

    result.fold((error) {
      final lang = ref.read(langControllerProvider);
      final message = parseError(error.dioExceptionType, lang);
      state = state.copyWith(error: 'Failed to download dialogue data: $message');
    }, (_) => null);

    state = state.copyWith(
      downloadingByZipNum: {...state.downloadingByZipNum}..update(zipNum.toString(), (value) => false),
    );
  }

  bool isDialogueDownloaded(String id) {
    return dialogueService.isDialogueDownloaded(id);
  }

  Dialogue? getDialogueById(String id) {
    return state.dialogues[id];
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
