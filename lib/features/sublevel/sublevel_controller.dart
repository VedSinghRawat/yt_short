import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/core/services/cleanup_service.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/sub_level_service.dart';
import 'package:myapp/core/shared_pref.dart';
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
    @Default(true) bool loading,
    @Default(false) bool hasFinishedVideo,
    @Default([]) List<String> levelIds,
    String? error,
  }) = _SublevelControllerState;

  bool get isFirstFetch => sublevels.isEmpty;
}

class SublevelController extends StateNotifier<SublevelControllerState> {
  final UserControllerState userController;
  final ISubLevelAPI subLevelAPI;
  final ILevelApi levelApi;
  final SubLevelService subLevelService;
  final FileService fileService;
  final OrderedIdsNotifier orderedIdNotifier;
  final AsyncValue<List<String>> orderedIdState;
  final StorageCleanupService storageCleanupService;

  SublevelController({
    required this.storageCleanupService,
    required this.userController,
    required this.subLevelAPI,
    required this.levelApi,
    required this.subLevelService,
    required this.fileService,
    required this.orderedIdNotifier,
    required this.orderedIdState,
  }) : super(const SublevelControllerState());

  Future<String?> _listByLevel(String levelId, int level) async {
    state = state.copyWith(
      loading: true,
      levelIds: [...state.levelIds, levelId],
    );

    try {
      final levelDTO = await levelApi.getById(levelId);

      final sublevels = {...state.sublevels};

      final currSubLevel = await userController.subLevel;

      if (state.isFirstFetch) {
        final subLevelDTO = await _fetchCurrSubLevel(levelDTO);
        final isVideoExists =
            await fileService.isVideoExists(levelDTO.id, subLevelDTO.videoFileName);

        if (isVideoExists) {
          state = state.copyWith(
            sublevels: {
              ...state.sublevels,
              SubLevel.fromSubLevelDTO(
                subLevelDTO,
                level,
                currSubLevel,
                levelId,
              ),
            },
          );
        }
      }

      final zipNumbers = levelDTO.subLevels.map((subLevelDTO) => subLevelDTO.zip).toSet();

      await subLevelService.getZipFiles(levelDTO.id, zipNumbers);

      for (var (index, sublevelDTO) in levelDTO.subLevels.indexed) {
        final subLevelNumber = index + 1;
        final isVideoExists =
            await fileService.isVideoExists(levelDTO.id, sublevelDTO.videoFileName);

        if (!isVideoExists) continue;

        SubLevel subLevel = SubLevel.fromSubLevelDTO(sublevelDTO, level, subLevelNumber, levelId);

        sublevels.add(subLevel);
      }

      state = state.copyWith(
        sublevels: {...state.sublevels, ...sublevels},
        loading: false,
      );

      return levelId;
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);

      final ids = [...state.levelIds];

      ids.remove(levelId);

      state = state.copyWith(levelIds: ids);

      return null;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<SubLevelDTO> _fetchCurrSubLevel(LevelDTO currLevelDTO) async {
    final currUserSubLevel = await userController.subLevel;

    final subLevelDTO = currLevelDTO.subLevels[currUserSubLevel - 1];

    await subLevelService.getSubLevelFile(currLevelDTO.id, subLevelDTO.zip);

    return subLevelDTO;
  }

  void setHasFinishedVideo(bool to) {
    state = state.copyWith(hasFinishedVideo: to);
  }

  Future<void> fetchSublevels() async {
    final currUserLevel = await userController.level;
    final isFirstFetch = state.isFirstFetch;

    if (isFirstFetch) {
      await orderedIdNotifier.getOrderedIds();
    }

    final orderedIds = orderedIdState.value;

    if (orderedIdState.hasError || orderedIds == null) {
      state = state.copyWith(error: 'Something Went Wrong. Please Try Again later', loading: false);
      return; // Exit early on error
    }

    final currLevelIndex = currUserLevel - 1;

    if (currLevelIndex < 0 || currLevelIndex >= orderedIds.length) {
      state = state.copyWith(
        error: 'All the levels are completed, please try again after some time',
        loading: false,
      );
      return;
    }

    final currLevelId = orderedIds[currLevelIndex];

    // Fetch current level if not already fetched
    final shouldFetchCurrLevel = !_isLevelFetched(currLevelId);

    if (shouldFetchCurrLevel) {
      await _listByLevel(currLevelId, currLevelIndex);
    }

    // Get surrounding level IDs
    final surroundingLevelIds = _getSurroundingLevelIds(currLevelIndex, orderedIds);

    // Fetch only the surrounding levels that haven't been fetched
    final fetchTasks = surroundingLevelIds
        .where((levelId) => levelId != null && !_isLevelFetched(levelId))
        .map((levelId) => _listByLevel(levelId!, orderedIds.indexOf(levelId)))
        .toList();

    await Future.wait(fetchTasks); // Fetch all missing levels in parallel

    if (fetchTasks.isNotEmpty || shouldFetchCurrLevel) {
      SharedPref.addCachedIds({...fetchTasks.whereType<String>(), currLevelId});
    }

    if (isFirstFetch) {
      final cachedIds = await SharedPref.getCachedIds();

      storageCleanupService.removeFurthestCachedIds(cachedIds.toList(), orderedIds, currLevelId);
    }
  }

  /// Helper function to check if a level is already fetched
  bool _isLevelFetched(String levelId) => state.levelIds.contains(levelId);

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
  final userController = ref.read(userControllerProvider);
  final subLevelAPI = ref.read(subLevelAPIProvider);
  final levelApi = ref.read(levelApiProvider);
  final subLevelService = ref.read(subLevelServiceProvider);
  final fileService = ref.read(fileServiceProvider);
  final orderedIdNotifier = ref.read(orderedIdsNotifierProvider.notifier);
  final orderedIdState = ref.watch(orderedIdsNotifierProvider);
  final storageCleanupService = ref.read(storageCleanupServiceProvider);

  return SublevelController(
    storageCleanupService: storageCleanupService,
    subLevelAPI: subLevelAPI,
    userController: userController,
    levelApi: levelApi,
    subLevelService: subLevelService,
    fileService: fileService,
    orderedIdNotifier: orderedIdNotifier,
    orderedIdState: orderedIdState,
  );
});
