import 'dart:io';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/services/cleanup/cleanup_service.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/services/sublevel/sublevel_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/models/level/level.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../apis/sublevel_api.dart';

part 'sublevel_controller.freezed.dart';
part 'sublevel_controller.g.dart';

@freezed
class SublevelControllerState with _$SublevelControllerState {
  const SublevelControllerState._();

  const factory SublevelControllerState({
    Set<SubLevel>? sublevels,
    @Default(false) bool hasFinishedVideo,
    // true when loading, false when loaded
    @Default({}) Map<String, bool> loadingByLevelId,
    String? error,
  }) = _SublevelControllerState;

  bool get isFirstFetch => sublevels?.isEmpty ?? true;
}

@Riverpod(keepAlive: true)
class SublevelController extends _$SublevelController {
  late final ISubLevelAPI subLevelAPI = ref.watch(subLevelAPIProvider);
  late final ILevelApi levelApi = ref.watch(levelApiProvider);
  late final SubLevelService subLevelService = ref.watch(subLevelServiceProvider);
  late final LevelController levelController = ref.watch(levelControllerProvider.notifier);
  late final StorageCleanupService storageCleanupService = ref.watch(storageCleanupServiceProvider);
  late final LevelService levelService = ref.watch(levelServiceProvider);
  late final LangController langController = ref.watch(langControllerProvider.notifier);

  @override
  SublevelControllerState build() => const SublevelControllerState();

  Future<String?> _listByLevel(String levelId, int level) async {
    state = state.copyWith(loadingByLevelId: {...state.loadingByLevelId, levelId: true});

    try {
      final levelDTO = await levelController.getLevel(levelId);

      if (levelDTO == null) return null;

      if (state.isFirstFetch) {
        // add curr sub level entry so first video can be played immediately
        final userSublevelNum = ref.read(userControllerProvider).subLevel;

        final currSublevel = SubLevel.fromSubLevelDTO(
          levelDTO.sub_levels[userSublevelNum - 1],
          level,
          userSublevelNum,
          levelId,
        );

        state = state.copyWith(
          sublevels: state.sublevels == null ? {currSublevel} : {...state.sublevels!, currSublevel},
        );
      }

      await subLevelService.getFiles(levelDTO);

      await subLevelService.getDialogueAudioFiles(levelDTO);

      await _addExistVideoSublevelEntries(levelDTO, level, levelId);

      state = state.copyWith(loadingByLevelId: {...state.loadingByLevelId}..remove(levelId));
      return levelId;
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel', error: e.toString(), stackTrace: stackTrace);
      state = state.copyWith(error: langController.choose(AppConstants.kErrorMessages[DioExceptionType.unknown]!));
      return null;
    } finally {
      state = state.copyWith(loadingByLevelId: {...state.loadingByLevelId}..remove(levelId));
    }
  }

  void setVideoPlayingError(String e) => state = state.copyWith(error: e);

  Future<void> _addExistVideoSublevelEntries(LevelDTO levelDTO, int level, String levelId) async {
    final entries = await FileService.listNames(Directory(PathService.levelVideosDirLocal(levelId)));

    final videoFiles = entries.toSet();

    final sublevels =
        levelDTO.sub_levels.where((dto) => videoFiles.contains("${dto.videoFilename}.mp4")).map((dto) {
          final index = levelDTO.sub_levels.indexOf(dto) + 1;
          return SubLevel.fromSubLevelDTO(dto, level, index, levelId);
        }).toSet();

    state = state.copyWith(sublevels: state.sublevels == null ? sublevels : {...state.sublevels!, ...sublevels});
  }

  void setHasFinishedVideo(bool to) => state = state.copyWith(hasFinishedVideo: to);

  Future<void> fetchSublevels() async {
    try {
      final asyncOrderIds = ref.read(levelControllerProvider);
      final isFirstFetch = state.isFirstFetch;

      if (state.error == AppConstants.allLevelsCompleted.hindi ||
          state.error == AppConstants.allLevelsCompleted.hinglish) {
        state = state.copyWith(error: null);
        await ref.read(levelControllerProvider.notifier).getOrderedIds();
      }

      if (asyncOrderIds.hasError) {
        state = state.copyWith(error: asyncOrderIds.error.toString());
        return;
      }

      state = state.copyWith(error: null);

      final orderedIds = asyncOrderIds.value;

      if (orderedIds == null) {
        state = state.copyWith(error: parseError(DioExceptionType.unknown, ref.read(langControllerProvider)));
        return;
      }

      final currUserLevel = ref.read(userControllerProvider).level;

      final currLevelIndex = currUserLevel - 1;

      final currLevelId = orderedIds[currLevelIndex];

      if (!_isLevelFetched(currLevelId)) {
        await _listByLevel(currLevelId, currUserLevel);
      }

      final surroundingLevelIds = _getSurroundingLevelIds(currLevelIndex, orderedIds);

      final fetchTasks =
          surroundingLevelIds
              .where((levelId) => levelId != null && !_isLevelFetched(levelId))
              .map((levelId) => _listByLevel(levelId!, orderedIds.indexOf(levelId) + 1))
              .toList();

      await Future.wait(fetchTasks);

      if (currLevelIndex < 0 || currUserLevel >= orderedIds.length) {
        final message = AppConstants.allLevelsCompleted(ref.read(langControllerProvider));

        state = state.copyWith(error: message);
      }

      if (isFirstFetch) {
        try {
          final localLevelIds = await FileService.listNames(
            Directory(PathService.levelsDocDir),
            type: EntitiesType.folders,
          );

          await _cleanOldLevels(localLevelIds, currLevelId);
        } catch (e) {
          developer.log('error in sublevel controller clean levels: $e', stackTrace: StackTrace.current);
        }
      }
    } catch (e) {
      developer.log('error in sublevel controller: $e', stackTrace: StackTrace.current);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _cleanOldLevels(List<String> orderedIds, String currLevelId) async {
    try {
      final localLevelIds = await FileService.listNames(
        Directory(PathService.levelsDocDir),
        type: EntitiesType.folders,
      );

      await storageCleanupService.cleanLocalFiles(localLevelIds, currLevelId);
    } catch (e) {
      developer.log('error in sublevel controller clean levels: $e', stackTrace: StackTrace.current);
    }
  }

  bool _isLevelFetched(String levelId) => state.loadingByLevelId[levelId] == false;

  List<String?> _getSurroundingLevelIds(int currIndex, List<String?> orderedIds) {
    return [
      orderedIds.elementAtOrNull(currIndex - 1),
      orderedIds.elementAtOrNull(currIndex + 1),
      orderedIds.elementAtOrNull(currIndex + 2),
    ];
  }
}
