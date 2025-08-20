import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/dialogues/dialogues.dart';
import 'package:myapp/services/dialogue/dialogue_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:fpdart/fpdart.dart';

part 'dialogue_controller.freezed.dart';
part 'dialogue_controller.g.dart';

@freezed
class DialogueControllerState with _$DialogueControllerState {
  const DialogueControllerState._();

  const factory DialogueControllerState({
    @Default({}) Map<String, Dialogue> dialogues,
    @Default({}) Map<String, bool> loadingByDialogueId,
    @Default({}) Map<String, bool> downloadingByZipNum,
  }) = _DialogueControllerState;
}

@Riverpod(keepAlive: true)
class DialogueController extends _$DialogueController {
  late final DialogueService dialogueService = ref.read(dialogueServiceProvider);

  @override
  DialogueControllerState build() => const DialogueControllerState();

  FutureEither<Dialogue> get(String id) async {
    state = state.copyWith(
      loadingByDialogueId: {...state.loadingByDialogueId}..update(id, (value) => true, ifAbsent: () => true),
    );

    final dialogueEither = await dialogueService.get(id);

    final result = dialogueEither.fold<Either<APIError, Dialogue>>(
      (error) {
        return left(error);
      },
      (dialogueDTO) {
        final dialogue = Dialogue.fromDTO(dialogueDTO, id);
        state = state.copyWith(
          dialogues: {...state.dialogues}..update(id, (value) => dialogue, ifAbsent: () => dialogue),
        );
        return right(dialogue);
      },
    );

    state = state.copyWith(loadingByDialogueId: {...state.loadingByDialogueId}..update(id, (value) => false));

    return result;
  }

  Future<APIError?> downloadData(int zipNum) async {
    state = state.copyWith(
      downloadingByZipNum: {...state.downloadingByZipNum}
        ..update(zipNum.toString(), (value) => true, ifAbsent: () => true),
    );

    final result = await dialogueService.downloadDialogueZip(zipNum);

    final error = result.fold((error) {
      return error;
    }, (_) => null);

    state = state.copyWith(
      downloadingByZipNum: {...state.downloadingByZipNum}..update(zipNum.toString(), (value) => false),
    );

    return error;
  }

  bool isDialogueDownloaded(String id) {
    return dialogueService.isDialogueDownloaded(id);
  }

  Dialogue? getDialogueById(String id) {
    return state.dialogues[id];
  }
}
