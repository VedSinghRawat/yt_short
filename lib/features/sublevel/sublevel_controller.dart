import 'dart:io';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/cleanup_service.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/services/sublevel_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/features/sublevel/ordered_ids_notifier.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/level/level.dart';
import '../../apis/sublevel_api.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_controller.freezed.dart';
part 'sublevel_controller.g.dart';

@freezed
class SublevelControllerState with _$SublevelControllerState {
  const SublevelControllerState._();

  const factory SublevelControllerState({
    @Default({}) Set<SubLevel> sublevels,
    @Default(false) bool hasFinishedVideo,
    @Default({}) Set<String> loadedLevelIds,
    @Default({}) Set<String> loadingLevelIds,
    String? error,
  }) = _SublevelControllerState;

  bool get isFirstFetch => sublevels.isEmpty;
}

@Riverpod(keepAlive: true)
class SublevelController extends _$SublevelController {
  @override
  SublevelControllerState build() => const SublevelControllerState();

  late final ISubLevelAPI subLevelAPI = ref.read(subLevelAPIProvider);
  late final ILevelApi levelApi = ref.read(levelApiProvider);
  late final SubLevelService subLevelService = ref.read(subLevelServiceProvider);
  late final FileService fileService = ref.read(fileServiceProvider);
  late final OrderedIdsNotifier orderedIdNotifier = ref.read(orderedIdsNotifierProvider.notifier);
  late final StorageCleanupService storageCleanupService = ref.read(storageCleanupServiceProvider);
  late final LevelService levelService = ref.read(levelServiceProvider);

  Future<String?> _listByLevel(String levelId, int level) async {
    state = state.copyWith(loadingLevelIds: {...state.loadingLevelIds, levelId});

    try {
      final levelDTOEither = await ref.read(levelServiceProvider).getLevel(levelId);

      final levelDTO = switch (levelDTOEither) {
        Right(value: final r) => r,
        Left(value: final l) => (() {
            state = state.copyWith(error: parseError(l.type));
            return null;
          })(),
      };

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

        state = state.copyWith(sublevels: {...state.sublevels, currSublevel});
      }

      await subLevelService.getVideoFiles(levelDTO);

      await _addExistVideoSublevelEntries(levelDTO, level, levelId);

      state = state.copyWith(loadedLevelIds: {...state.loadedLevelIds, levelId});
      return levelId;
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);
      state = state.copyWith(error: unknownErrorMsg);
      return null;
    } finally {
      state = state.copyWith(loadingLevelIds: {...state.loadingLevelIds}..remove(levelId));
    }
  }

  void setVideoPlayingError(String e) => state = state.copyWith(error: e);

  Future<void> _addExistVideoSublevelEntries(
    LevelDTO levelDTO,
    int level,
    String levelId,
  ) async {
    final entries = await FileService.listEntities(
      Directory(
        levelService.getVideoDirPath(levelId),
      ),
    );

    final videoFiles = entries.toSet();

    final sublevels = levelDTO.sub_levels
        .where(
      (dto) => videoFiles.contains(
        "${dto.videoFilename}.mp4",
      ),
    )
        .map(
      (dto) {
        final index = levelDTO.sub_levels.indexOf(dto) + 1;
        return SubLevel.fromSubLevelDTO(
          dto,
          level,
          index,
          levelId,
        );
      },
    ).toSet();

    state = state.copyWith(sublevels: {...state.sublevels, ...sublevels});
  }

  void setHasFinishedVideo(bool to) => state = state.copyWith(hasFinishedVideo: to);

  Future<void> handleFetchSublevels() async {
    try {
      final asyncOrderIds = ref.read(orderedIdsNotifierProvider);
      final isFirstFetch = state.isFirstFetch;

      if (asyncOrderIds.hasError) {
        state = state.copyWith(error: asyncOrderIds.error.toString());
        return;
      }

      state = state.copyWith(error: null);

      final orderedIds = asyncOrderIds.value;

      if (orderedIds == null) {
        state = state.copyWith(error: unknownErrorMsg);
        return;
      }

      String currLevelId = await fetchSublevels(orderedIds);

      if (isFirstFetch) await _cleanOldLevels(orderedIds, currLevelId);
    } catch (e) {
      developer.log('error in sublevel controller: $e', stackTrace: StackTrace.current);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String> fetchSublevels(List<String> orderedIds) async {
    final currUserLevel = ref.read(userControllerProvider).level;

    final currLevelIndex = currUserLevel - 1;

    final currLevelId = orderedIds[min(currLevelIndex, orderedIds.length - 1)];

    if (!_isLevelFetched(currLevelId)) {
      await _listByLevel(currLevelId, currUserLevel);
    }

    final surroundingLevelIds = _getSurroundingLevelIds(currLevelIndex, orderedIds);

    final fetchTasks = surroundingLevelIds
        .where((levelId) => levelId != null && !_isLevelFetched(levelId))
        .map((levelId) => _listByLevel(levelId!, orderedIds.indexOf(levelId) + 1))
        .toList();

    await Future.wait(fetchTasks);

    if (currLevelIndex < 0 || currUserLevel >= orderedIds.length) {
      state = state.copyWith(
        error: 'These are all the lessons for now, Check in after sometime for new content',
      );
    }

    return currLevelId;
  }

  Future<void> _cleanOldLevels(List<String> orderedIds, String currLevelId) async {
    try {
      final cachedIds = await FileService.listEntities(
        Directory(levelService.levelsDocDirPath),
        type: EntitiesType.folders,
      );

      await storageCleanupService.removeFurthestCachedIds(
        cachedIds,
        orderedIds,
        currLevelId,
      );
    } catch (e) {
      developer.log('error in sublevel controller clean levels: $e',
          stackTrace: StackTrace.current);
    }
  }

  bool _isLevelFetched(String levelId) =>
      state.loadedLevelIds.contains(levelId) || state.loadingLevelIds.contains(levelId);

  List<String?> _getSurroundingLevelIds(int currIndex, List<String?> orderedIds) {
    final int maxIndex = orderedIds.length - 1;
    return [
      currIndex + 1 <= maxIndex ? orderedIds[currIndex + 1] : null,
      currIndex - 1 >= 0 ? orderedIds[currIndex - 1] : null,
      currIndex + 2 <= maxIndex ? orderedIds[currIndex + 2] : null,
    ];
  }
}
