import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/services/cleanup_service.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/sub_level_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/features/sublevel/ordered_ids_notifier.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/level/level.dart';
import 'dart:developer' as developer;
import '../../apis/sub_level_api.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:flutter/foundation.dart';

part 'sublevel_controller.freezed.dart';

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

class SublevelController extends StateNotifier<SublevelControllerState> {
  final ISubLevelAPI subLevelAPI;
  final ILevelApi levelApi;
  final SubLevelService subLevelService;
  final FileService fileService;
  final OrderedIdsNotifier orderedIdNotifier;
  final StorageCleanupService storageCleanupService;
  final Ref ref;

  SublevelController({
    required this.ref,
    required this.storageCleanupService,
    required this.subLevelAPI,
    required this.levelApi,
    required this.subLevelService,
    required this.fileService,
    required this.orderedIdNotifier,
  }) : super(const SublevelControllerState());

  Future<String?> _listByLevel(String levelId, int level) async {
    state = state.copyWith(
      loadingLevelIds: {...state.loadingLevelIds, levelId},
    );

    Console.timeStart('listlevel$level');
    developer.log('loadingLevelIds ${state.loadingLevelIds}');

    try {
      final levelDTOEither = await levelApi.getById(levelId);

      final levelDTO = switch (levelDTOEither) {
        Right(value: final r) => r,
        Left(value: final l) => (() {
            String e = genericErrorMessage;

            if (dioConnectionErrors.contains(l.type)) {
              e = internetError;
            }

            state = state.copyWith(error: e);

            return null;
          })(),
      };

      if (levelDTO == null) return null;

      final sublevels = {...state.sublevels};

      if (state.isFirstFetch) {
        Console.timeStart('first-fetch');

        await _fetchCurrSubLevelZip(levelDTO);

        await _addSublevelEntries(levelDTO, sublevels, level, levelId);

        Console.timeEnd('first-fetch');
      }

      final zipNumbers = levelDTO.subLevels.map((subLevelDTO) => subLevelDTO.zip).toSet();

      await subLevelService.getZipFiles(levelDTO.id, zipNumbers);

      await _addSublevelEntries(levelDTO, sublevels, level, levelId);

      state = state.copyWith(
        loadedLevelIds: {...state.loadedLevelIds, levelId},
      );
      return levelId;
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);

      state = state.copyWith(error: internetError);

      return null;
    } finally {
      state = state.copyWith(
        loadingLevelIds: {...state.loadingLevelIds}..remove(levelId),
      );
      Console.timeEnd('listlevel$level');
    }
  }

  void setVideoPlayingError(String e) {
    state = state.copyWith(error: e);
  }

  Future<void> _addSublevelEntries(
      LevelDTO levelDTO, Set<SubLevel> sublevels, int level, String levelId) async {
    final path = fileService.getVideoDirPath(levelDTO.id);

    final entries = await compute(_listEntities, path);

    sublevels.addAll(
      levelDTO.subLevels
          .where(
            (element) => entries.any((e) => e == "${element.videoFileName}.mp4"),
          )
          .map(
            (dto) => SubLevel.fromSubLevelDTO(
              dto,
              level,
              levelDTO.subLevels.indexOf(dto) + 1,
              levelId,
            ),
          ),
    );

    state = state.copyWith(
      sublevels: {...state.sublevels, ...sublevels},
    );
  }

  Future<SubLevelDTO> _fetchCurrSubLevelZip(LevelDTO currLevelDTO) async {
    final currUserSubLevel = await ref.read(userControllerProvider).subLevel;

    final subLevelDTO = currLevelDTO.subLevels[currUserSubLevel - 1];

    await subLevelService.getSubLevelFile(currLevelDTO.id, subLevelDTO.zip);

    return subLevelDTO;
  }

  void setHasFinishedVideo(bool to) {
    state = state.copyWith(hasFinishedVideo: to);
  }

  Future<void> fetchSublevels() async {
    try {
      developer.log('fetchSublevels');
      final userLevelIndex = await ref.read(userControllerProvider).level;
      final storedCurrId = await ref.read(userControllerProvider).levelId;

      state = state.copyWith(
        error: null,
      );

      final isFirstFetch = state.isFirstFetch;

      if (isFirstFetch) await orderedIdNotifier.getOrderedIds();

      final asyncOrderIds = ref.read(orderedIdsNotifierProvider);

      if (asyncOrderIds.hasError) {
        state = state.copyWith(error: asyncOrderIds.error.toString());
        return;
      }

      final orderedIds = asyncOrderIds.value;

      if (orderedIds == null) {
        state = state.copyWith(
          error: genericErrorMessage,
        );
        return;
      }

      // handle case were we move any level back to the curr user level ;

      final levelIdIndex =
          storedCurrId != null ? orderedIds.indexOf(storedCurrId) + 1 : userLevelIndex;

      final currUserLevel = levelIdIndex > userLevelIndex ? levelIdIndex : userLevelIndex;

      final currLevelIndex = currUserLevel - 1;

      final currLevelId = orderedIds[currLevelIndex];

      // Fetch current level if not already fetched
      final shouldFetchCurrLevel = !_isLevelFetched(currLevelId);

      if (shouldFetchCurrLevel) {
        await _listByLevel(currLevelId, currUserLevel);
      }

      // Get surrounding level IDs
      final surroundingLevelIds = _getSurroundingLevelIds(currLevelIndex, orderedIds);

      // Fetch only the surrounding levels that haven't been fetched
      final fetchTasks = surroundingLevelIds
          .where((levelId) => levelId != null && !_isLevelFetched(levelId))
          .map((levelId) => _listByLevel(levelId!, orderedIds.indexOf(levelId) + 1))
          .toList();

      await Future.wait(fetchTasks); // Fetch all missing levels in parallel

      if (currLevelIndex < 0 || currUserLevel >= orderedIds.length) {
        state = state.copyWith(
          error: 'All the levels are completed, please try again after some time',
        );
      }

      if (isFirstFetch) {
        final cachedIds = await compute(_listEntities, fileService.levelsDocDirPath);

        developer.log('cached ids is $cachedIds');

        storageCleanupService.removeFurthestCachedIds(cachedIds, orderedIds, currLevelId);
      }
    } catch (e) {
      developer.log('error in sublevel controller: $e');
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  Future<List<String>> _listEntities(String path) {
    return FileService.listEntities(
      Directory(path),
      type: EntitiesType.folders,
    );
  }

  /// Helper function to check if a level is already fetched
  bool _isLevelFetched(String levelId) =>
      state.loadedLevelIds.contains(levelId) || state.loadingLevelIds.contains(levelId);

  /// Helper function to get surrounding level IDs
  List<String?> _getSurroundingLevelIds(int currIndex, List<String?> orderedIds) {
    final int maxIndex = orderedIds.length - 1;

    return [
      currIndex + 1 <= maxIndex ? orderedIds[currIndex + 1] : null, // Next level
      currIndex - 1 >= 0 ? orderedIds[currIndex - 1] : null, // Previous level
      currIndex + 2 <= maxIndex ? orderedIds[currIndex + 2] : null, // Next to next level
    ];
  }
}

final sublevelControllerProvider =
    StateNotifierProvider<SublevelController, SublevelControllerState>((ref) {
  final subLevelAPI = ref.read(subLevelAPIProvider);
  final levelApi = ref.read(levelApiProvider);
  final subLevelService = ref.read(subLevelServiceProvider);
  final fileService = ref.read(fileServiceProvider);
  final orderedIdNotifier = ref.read(orderedIdsNotifierProvider.notifier);
  final storageCleanupService = ref.read(storageCleanupServiceProvider);

  return SublevelController(
    storageCleanupService: storageCleanupService,
    subLevelAPI: subLevelAPI,
    ref: ref,
    levelApi: levelApi,
    subLevelService: subLevelService,
    fileService: fileService,
    orderedIdNotifier: orderedIdNotifier,
  );
});
