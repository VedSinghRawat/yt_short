import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants/constants.dart';
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
    @Default({}) Map<String, SubLevel> sublevelMap,
    @Default({}) Map<int, int> subLevelCountByLevel,
    bool? loading,
    @Default(false) bool hasFinishedVideo,
    Level? currentLevel,
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
    if (state.subLevelCountByLevel.containsKey(levelId) || state.loading == true) return;

    state = state.copyWith(loading: true);
    try {
      final levelDTO = await levelApi.getById(levelId);

      Map<String, SubLevel> sublevelMap = {...state.sublevelMap};
      Map<int, int> subLevelCountByLevel = {...state.subLevelCountByLevel};

      subLevelCountByLevel[level] = levelDTO.subLevels.length;

      final currSubLevel = await userController.subLevel;

      final isFirstLounch = subLevelCountByLevel.isEmpty;

      if (isFirstLounch) {
        final subLevelDTO = await _fetchCurrSubLevel(levelDTO);

        if (await fileService.isVideoExists(levelDTO.id, subLevelDTO.videoFileName)) {
          sublevelMap["${levelDTO.id}-$currSubLevel"] =
              SubLevel.fromSubLevelDTO(subLevelDTO, level, currSubLevel, levelId);
        }
      }

      final zipNumbers = levelDTO.subLevels.map((subLevelDTO) => subLevelDTO.zip).toSet();

      await subLevelService.getZipFiles(levelDTO.id, zipNumbers);

      for (var (index, sublevelDTO) in levelDTO.subLevels.indexed) {
        final subLevelNumber = index + 1;

        if (!await fileService.isVideoExists(levelDTO.id, sublevelDTO.videoFileName)) continue;

        SubLevel subLevel = SubLevel.fromSubLevelDTO(sublevelDTO, level, subLevelNumber, levelId);

        sublevelMap["${levelDTO.id}-$subLevelNumber"] = subLevel;
      }

      // Update state
      state = state.copyWith(
        sublevelMap: sublevelMap,
        subLevelCountByLevel: subLevelCountByLevel,
      );

      // Fetch next and previous levels if first launch
      if (isFirstLounch) {
        await _listByLevel(levelDTO.nextId, level + 1);
        await _listByLevel(levelDTO.prevId, level - 1);
      }
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);
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

  Future<void> fetchSublevels() async {
    final currUserLevel = await userController.level;
    final currUserSubLevel = await userController.subLevel;

    final fetchCurrLevel = !state.subLevelCountByLevel.containsKey(currUserLevel);
    final currLevel = state.currentLevel;

    // Fetch the current level if not already in cache
    if (fetchCurrLevel) {
      await _listByLevel(currLevel!.id, currUserLevel);
    }

    final prevLevel = currUserLevel - 1;
    final fetchPrevLevel = currUserSubLevel < kSubLevelAPIBuffer &&
        prevLevel >= 1 &&
        !state.subLevelCountByLevel.containsKey(prevLevel);
    // Fetch previous level if near start of sublevels
    if (fetchPrevLevel) {
      await _listByLevel(currLevel!.prevId, prevLevel);
    }

    final currLevelSublevelCount = state.subLevelCountByLevel[currUserLevel] ?? 0;
    final nextLevel = currUserLevel + 1;
    final fetchNextLevel = currUserSubLevel > currLevelSublevelCount - kSubLevelAPIBuffer &&
        !state.subLevelCountByLevel.containsKey(nextLevel);
    // Fetch next level if near the end of sublevels
    if (fetchNextLevel) {
      await _listByLevel(currLevel!.nextId, nextLevel);
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
