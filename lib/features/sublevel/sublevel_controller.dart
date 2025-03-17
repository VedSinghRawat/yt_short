import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/sub_level_service.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/level/level.dart';
import 'dart:developer' as developer;
import '../../apis/sub_level_api.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:flutter/foundation.dart';

part 'sublevel_controller.freezed.dart';

@freezed
class SublevelControllerState with _$SublevelControllerState {
  const factory SublevelControllerState({
    @Default({}) Set<SubLevel> sublevels,
    bool? loading,
    @Default(false) bool hasFinishedVideo,
    @Default(null) Map<int, Level?>? levelByLevelNum,
  }) = _SublevelControllerState;
}

class SublevelController extends StateNotifier<SublevelControllerState> {
  final UserControllerState userController;
  final ISubLevelAPI subLevelAPI;
  final LevelApi levelApi;
  final SubLevelService subLevelService;
  final FileService fileService;

  SublevelController({
    required this.userController,
    required this.subLevelAPI,
    required this.levelApi,
    required this.subLevelService,
    required this.fileService,
  }) : super(const SublevelControllerState());

  Future<void> _listByLevel(String levelId, int level) async {
    if (state.levelByLevelNum?[level] != null || state.loading == true) return;

    state = state.copyWith(loading: true);
    try {
      Console.timeStart('getById $levelId');
      final levelDTO = await levelApi.getById(levelId);

      final sublevels = {...state.sublevels};
      final isFirstLaunch = sublevels.isEmpty;

      final currSubLevel = await userController.subLevel;

      if (isFirstLaunch) {
        final subLevelDTO = await _fetchCurrSubLevel(levelDTO);
        final isVideoExists =
            await fileService.isVideoExists(levelDTO.id, subLevelDTO.videoFileName);

        if (isVideoExists) {
          sublevels.add(SubLevel.fromSubLevelDTO(subLevelDTO, level, currSubLevel, levelId));
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

      _updateState(level, levelId, levelDTO, sublevels);

      // Fetch next and previous levels if first launch
      if (isFirstLaunch) {
        if (levelDTO.nextId != null) await _listByLevel(levelDTO.nextId!, level + 1);
        if (levelDTO.prevId != null) await _listByLevel(levelDTO.prevId!, level - 1);
      }

      Console.timeEnd('getById $levelId');
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  void _updateState(int level, String levelId, LevelDTO levelDTO, Set<SubLevel> sublevels) {
    final Map<int, Level?> levelByLevelNum = {
      if (state.levelByLevelNum != null) ...state.levelByLevelNum!,
      level: Level.fromLevelDTO(levelDTO),
    };

    if (levelDTO.nextId != null && levelByLevelNum[level + 1] == null) {
      levelByLevelNum[level + 1] = null;
    }

    if (levelDTO.prevId != null && levelByLevelNum[level - 1] == null) {
      levelByLevelNum[level - 1] = null;
    }

    // Update state
    state = state.copyWith(
      sublevels: sublevels,
      levelByLevelNum: levelByLevelNum,
      loading: false,
    );
  }

  Future<SubLevelDTO> _fetchCurrSubLevel(LevelDTO currLevelDTO) async {
    final currUserSubLevel = await userController.subLevel;

    final subLevelDTO = currLevelDTO.subLevels[currUserSubLevel - 1];

    await subLevelService.getSubLevelFile(currLevelDTO.id, subLevelDTO.zip);

    return subLevelDTO;
  }

  bool _isLevelInCache(int level) {
    return state.levelByLevelNum?[level] != null;
  }

  Future<void> fetchSublevels() async {
    final currUserLevel = await userController.level;
    final currUserSubLevel = await userController.subLevel;

    final fetchCurrLevel = !_isLevelInCache(currUserLevel);

    final currLevelId = state.levelByLevelNum?[currUserLevel]?.id ??
        userController.currentUser?.levelId ??
        'lS_7kKC2Etk'; // TODO: change from info service not its dummy

    final prevLevelId = state.levelByLevelNum?[currUserLevel - 1]?.id;
    final nextLevelId = state.levelByLevelNum?[currUserLevel + 1]?.id;

    // Fetch the current level if not already in cache
    if (fetchCurrLevel) {
      await _listByLevel(currLevelId, currUserLevel);
    }

    final prevLevel = currUserLevel - 1;
    final fetchPrevLevel =
        currUserSubLevel < kSubLevelAPIBuffer && prevLevel >= 1 && !_isLevelInCache(prevLevel);
    // Fetch previous level if near start of sublevels
    if (fetchPrevLevel && prevLevelId != null) {
      await _listByLevel(prevLevelId, prevLevel);
    }

    final currLevelSublevelCount = state.levelByLevelNum?[currUserLevel]?.subLevelCount ?? 0;

    final nextLevel = currUserLevel + 1;

    final fetchNextLevel = currUserSubLevel > currLevelSublevelCount - kSubLevelAPIBuffer &&
        !_isLevelInCache(nextLevel);

    // Fetch next level if near the end of sublevels
    if (fetchNextLevel && nextLevelId != null) {
      await _listByLevel(nextLevelId, nextLevel);
    }
  }

  void setHasFinishedVideo(bool hasFinishedVideo) {
    state = state.copyWith(hasFinishedVideo: hasFinishedVideo);
  }
}

final sublevelControllerProvider =
    StateNotifierProvider<SublevelController, SublevelControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final subLevelAPI = ref.read(subLevelAPIProvider);
  final levelApi = ref.read(levelApiProvider);
  final subLevelService = ref.read(subLevelServiceProvider);
  final fileService = ref.read(fileServiceProvider);

  return SublevelController(
    subLevelAPI: subLevelAPI,
    userController: userController,
    levelApi: levelApi,
    subLevelService: subLevelService,
    fileService: fileService,
  );
});
