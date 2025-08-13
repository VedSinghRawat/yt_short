import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/dialogue/dialogue_controller.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:developer' as developer;

part 'level_controller.freezed.dart';
part 'level_controller.g.dart';

@freezed
class LevelControllerState with _$LevelControllerState {
  const LevelControllerState._();

  const factory LevelControllerState({
    List<String>? orderedIds,
    // true when loading, false when loaded, null when not tried to load/fetch
    @Default({}) Map<String, bool> loadingById,
    String? error,
  }) = _LevelControllerState;
}

@Riverpod(keepAlive: true)
class LevelController extends _$LevelController {
  late final levelService = ref.read(levelServiceProvider);
  late final subLevelController = ref.read(sublevelControllerProvider.notifier);
  late final dialogueController = ref.read(dialogueControllerProvider.notifier);

  @override
  LevelControllerState build() => const LevelControllerState();

  Future<void> getLevel(String id) async {
    final orderedIdsForLog = state.orderedIds ?? const [];
    final levelNumForLog = orderedIdsForLog.indexOf(id) + 1;
    developer.log('[LevelController] getLevel: start level=${levelNumForLog > 0 ? levelNumForLog : 'n/a'} id=$id');
    state = state.copyWith(loadingById: {...state.loadingById}..update(id, (value) => true, ifAbsent: () => true));

    final levelDTOEither = await levelService.getLevel(id);
    List<SubLevelDTO> sublevelDTOs = [];
    Set<String> dialogueIds = {};

    final level = levelDTOEither.fold(
      (l) {
        state = state.copyWith(error: l.message);
        return null;
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

        return level;
      },
    );

    state = state.copyWith(loadingById: {...state.loadingById}..update(id, (value) => false));

    if (level == null) return;

    await Future.wait([
      ...dialogueIds.map((dialogueId) async {
        final dialogue = await dialogueController.get(dialogueId);
        if (dialogue == null) return;
        await dialogueController.downloadData(dialogue.zipNum);
      }),
      ...sublevelDTOs.map((subLevelDTO) => subLevelController.getAssets(subLevelDTO, level.id)),
    ]);
    developer.log('[LevelController] getLevel: complete level=${levelNumForLog > 0 ? levelNumForLog : 'n/a'} id=$id');
  }

  Future<void> getOrderedIds() async {
    final result = await levelService.getOrderedIds();

    await result.fold(
      (error) {
        state = state.copyWith(error: error.message);
        // Try to load from local storage as fallback
        final localIds = SharedPref.get(PrefKey.orderedIds);
        if (localIds != null) {
          state = state.copyWith(orderedIds: localIds);
        }
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
      },
    );
  }

  Future<void> fetchLevels() async {
    developer.log('[LevelController] fetchLevels: start');
    final orderedIds = state.orderedIds;
    developer.log('[LevelController] fetchLevels: orderedIds=$orderedIds');

    if (orderedIds == null) {
      state = state.copyWith(error: parseError(DioExceptionType.unknown, ref.read(langControllerProvider)));
      return;
    }

    state = state.copyWith(error: null);
    final progress = ref.read(uIControllerProvider).currentProgress;
    String currUserLevelId = progress?.levelId ?? orderedIds.first;
    final anchorIdx = orderedIds.indexOf(currUserLevelId);
    final anchorLevelNum = anchorIdx >= 0 ? anchorIdx + 1 : -1;
    developer.log(
      '[LevelController] anchorLevel=$anchorLevelNum | progressL-S=${progress?.level}-${progress?.subLevel} | orderedIdsLen=${orderedIds.length}',
    );

    final loading = state.loadingById;
    if (loading[currUserLevelId] == null) {
      developer.log('[LevelController] fetchLevels: fetching currentLevel=$anchorLevelNum');
      await getLevel(currUserLevelId);
    } else {
      developer.log(
        '[LevelController] fetchLevels: current already known level=$anchorLevelNum loading=${loading[currUserLevelId]}',
      );
    }

    // Build fetch list using flexible surrounding selection
    final toFetch = _getSurroundingLevelIds();
    final toFetchLevels = toFetch.map((id) => orderedIds.indexOf(id) + 1).toList();
    developer.log('[LevelController] fetchLevels: surrounding toFetchLevels=$toFetchLevels');

    final fetchLevelReqs = <Future<void>>[];
    for (final levelId in toFetch) {
      final status = loading[levelId];
      final lvlNum = orderedIds.indexOf(levelId) + 1;
      if (status == null) {
        developer.log('[LevelController] fetchLevels: queue fetch level=$lvlNum');
        fetchLevelReqs.add(getLevel(levelId));
      } else {
        developer.log('[LevelController] fetchLevels: skip level=$lvlNum (loading=$status)');
      }
    }

    await Future.wait(fetchLevelReqs);

    if (currUserLevelId == orderedIds.last) {
      final message = AppConstants.allLevelsCompleted(ref.read(langControllerProvider));

      state = state.copyWith(error: message);
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
    final levelNums = result.map((id) => orderedIds.indexOf(id) + 1).toList();
    developer.log(
      '[LevelController] _getSurroundingLevelIds: anchorLevel=${idx + 1} window=[$start..$end] -> levels=$levelNums',
    );
    return result;
  }
}
