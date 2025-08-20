import 'dart:developer' as developer;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/dialogue/dialogue_controller.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'level_controller.freezed.dart';
part 'level_controller.g.dart';

@freezed
class LevelControllerState with _$LevelControllerState {
  const LevelControllerState._();

  const factory LevelControllerState({
    List<String>? orderedIds,
    // true when loading, false when loaded, null when not tried to load/fetch
    @Default({}) Map<String, bool> loadingById,
  }) = _LevelControllerState;
}

@Riverpod(keepAlive: true)
class LevelController extends _$LevelController {
  late final levelService = ref.read(levelServiceProvider);
  late final subLevelController = ref.read(sublevelControllerProvider.notifier);
  late final dialogueController = ref.read(dialogueControllerProvider.notifier);

  @override
  LevelControllerState build() => const LevelControllerState();

  FutureEither<Level?> getLevel(String id) async {
    // removed verbose developer logs
    state = state.copyWith(loadingById: {...state.loadingById}..update(id, (value) => true, ifAbsent: () => true));

    final levelDTOEither = await levelService.getLevel(id);
    List<SubLevelDTO> sublevelDTOs = [];
    Set<String> dialogueIds = {};

    final foldRes = levelDTOEither.fold<Either<APIError, Level>>(
      (l) {
        return left(l);
      },
      (r) {
        final level = Level.fromLevelDTO(r);
        int i = 1;
        sublevelDTOs = r.sub_levels;
        final index = state.orderedIds?.indexOf(level.id);

        for (var subLevelDTO in r.sub_levels) {
          subLevelController.set(subLevelDTO, level.id, i++, index != null ? index + 1 : 1);
          subLevelDTO.whenOrNull(video: (v) => dialogueIds.addAll(v.dialogues.map((d) => d.id)));
        }

        return right(level);
      },
    );

    state = state.copyWith(loadingById: {...state.loadingById}..update(id, (value) => false));

    await foldRes.fold<FutureEither<void>>(
      (error) async {
        return left(error);
      },
      (level) async {
        await Future.wait([
          ...dialogueIds.map((dialogueId) async {
            final dialogueResult = await dialogueController.get(dialogueId);
            final dialogue = dialogueResult.fold((error) => null, (dialogue) => dialogue);
            if (dialogue == null) return;
            final downloadError = await dialogueController.downloadData(dialogue.zipNum);
            if (downloadError != null) {
              developer.log('Error downloading dialogue data: ${downloadError.message}', error: downloadError.trace);
            }
          }),
          ...sublevelDTOs.map((subLevelDTO) async {
            final assetError = await subLevelController.getAssets(subLevelDTO, level.id);
            if (assetError != null) {
              developer.log('Error getting sublevel assets: ${assetError.message}', error: assetError.trace);
            }
          }),
        ]);
        return right(null);
      },
    );

    return foldRes;
  }

  FutureEither<List<String>?> getOrderedIds() async {
    final result = await levelService.getOrderedIds();

    final orderedIds = await result.fold(
      (error) async {
        // Try to load from local storage as fallback
        final localIds = SharedPref.get(PrefKey.orderedIds);
        if (localIds != null) {
          state = state.copyWith(orderedIds: localIds);
        }
        return null;
      },
      (orderedIds) async {
        if (orderedIds != null) {
          // New data received, store it
          await SharedPref.store(PrefKey.orderedIds, orderedIds);
          state = state.copyWith(orderedIds: orderedIds);
        } else {
          // 304 Not Modified - load from local storage
          final localIds = SharedPref.get(PrefKey.orderedIds);
          if (localIds != null) {
            state = state.copyWith(orderedIds: localIds);
          }
        }
        return orderedIds;
      },
    );

    return right(orderedIds);
  }

  Future<void> fetchLevels() async {
    final orderedIds = state.orderedIds;

    if (orderedIds == null) {
      return;
    }

    final progress = ref.read(uIControllerProvider).currentProgress;
    String currUserLevelId = progress?.levelId ?? orderedIds.first;

    final loading = state.loadingById;
    if (loading[currUserLevelId] == null) {
      await getLevel(currUserLevelId);
    }

    // Build fetch list using flexible surrounding selection
    final toFetch = _getSurroundingLevelIds();

    final fetchLevelReqs = <Future<void>>[];
    for (final levelId in toFetch) {
      final status = loading[levelId];
      if (status == null) {
        fetchLevelReqs.add(getLevel(levelId));
      }
    }

    await Future.wait(fetchLevelReqs);

    if (currUserLevelId == orderedIds.last) {
      // All levels completed - this is not an error, just informational
      developer.log('All levels completed');
    }
  }

  /// Returns level ids around current progress anchor in a single loop
  /// Window size from AppConstants.kMaxBeforeLevels/kMaxAfterLevels
  List<String> _getSurroundingLevelIds() {
    final orderedIds = state.orderedIds;
    if (orderedIds == null || orderedIds.isEmpty) return const [];

    final progress = ref.read(uIControllerProvider).currentProgress;
    final anchorLevelId = progress?.levelId ?? orderedIds.first;

    var idx = orderedIds.indexOf(anchorLevelId);
    if (idx == -1) idx = 0;

    final start = idx - AppConstants.kMaxBeforeLevels;
    final end = idx + AppConstants.kMaxAfterLevels;

    final result = <String>[];
    for (int i = start; i <= end; i++) {
      if (i < 0 || i >= orderedIds.length) continue;
      result.add(orderedIds[i]);
    }
    return result;
  }
}
