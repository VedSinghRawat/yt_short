import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/util_classes.dart';
import 'package:myapp/core/services/youtube_service.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;
import '../../apis/sub_level_api.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

class SublevelControllerState {
  // the key will be $level-$subLevel
  final Map<String, SubLevel> sublevelMap;
  // level against the key attribute of sublevel
  final Map<int, int> subLevelCountByLevel;
  final bool hasFinishedVideo;
  final Map<String, Media> ytUrls;

  final bool? loading;

  SublevelControllerState({
    this.sublevelMap = const {},
    this.subLevelCountByLevel = const {},
    this.loading,
    this.hasFinishedVideo = false,
    this.ytUrls = const {},
  });

  SublevelControllerState copyWith({
    Map<String, SubLevel>? sublevelMap,
    Map<int, int>? subLevelCountByLevel,
    bool? loading,
    bool? hasFinishedVideo,
    Map<String, Media>? ytUrls,
  }) {
    return SublevelControllerState(
      sublevelMap: sublevelMap ?? this.sublevelMap,
      subLevelCountByLevel: subLevelCountByLevel ?? this.subLevelCountByLevel,
      loading: loading ?? this.loading,
      hasFinishedVideo: hasFinishedVideo ?? this.hasFinishedVideo,
      ytUrls: ytUrls ?? this.ytUrls,
    );
  }
}

class SublevelController extends StateNotifier<SublevelControllerState> {
  final UserControllerState userController;
  final ISubLevelAPI subLevelAPI;
  final YoutubeService ytService;

  SublevelController({
    required this.userController,
    required this.subLevelAPI,
    required this.ytService,
  }) : super(SublevelControllerState());

  Future<void> _listByLevel(int level) async {
    if (state.subLevelCountByLevel.containsKey(level) || state.loading == true) return;

    state = state.copyWith(loading: true);
    try {
      final tempSublevels = await subLevelAPI.listByLevel(firstLevelId);

      Map<String, SubLevel> sublevelMap = {...state.sublevelMap};
      Map<int, int> subLevelCountByLevel = {...state.subLevelCountByLevel};

      subLevelCountByLevel[level] = tempSublevels.length;

      for (var sublevel in tempSublevels) {
        sublevelMap["${sublevel.level}-${sublevel.subLevel}"] = sublevel;
      }

      state = state.copyWith(
        sublevelMap: sublevelMap,
        subLevelCountByLevel: subLevelCountByLevel,
      );
    } catch (e, stackTrace) {
      developer.log('Error in SublevelController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> fetchRelavantYturls(List<SubLevel> tempSublevels) async {
    final userSubLevel = await userController.subLevel;

    if (state.ytUrls.isNotEmpty) return;

    final relevantSubLevels = {userSubLevel - 1, userSubLevel, userSubLevel + 1};

    final ytIds = tempSublevels
        .where((e) => relevantSubLevels.contains(e.subLevel))
        .map((e) => e.ytId)
        .toList();

    await fetchYtUrls(ytIds);
  }

  Future<void> fetchYtUrls(List<String> ytIds) async {
    final ytUrls = await ytService.listMediaUrls(ytIds);
    state = state.copyWith(ytUrls: {...state.ytUrls, ...ytUrls});
  }

  Future<void> fetchSublevels() async {
    final currUserLevel = await userController.level;
    final currUserSubLevel = await userController.subLevel;

    final fetchCurrLevel = !state.subLevelCountByLevel.containsKey(currUserLevel);

    // Fetch the current level if not already in cache
    if (fetchCurrLevel) {
      await _listByLevel(currUserLevel);
    }

    final prevLevel = currUserLevel - 1;
    final fetchPrevLevel = currUserSubLevel < kSubLevelAPIBuffer &&
        prevLevel >= 1 &&
        !state.subLevelCountByLevel.containsKey(prevLevel);
    // Fetch previous level if near start of sublevels
    if (fetchPrevLevel) {
      await _listByLevel(prevLevel);
    }

    final currLevelSublevelCount = state.subLevelCountByLevel[currUserLevel] ?? 0;
    final nextLevel = currUserLevel + 1;
    final fetchNextLevel = currUserSubLevel > currLevelSublevelCount - kSubLevelAPIBuffer &&
        !state.subLevelCountByLevel.containsKey(nextLevel);
    // Fetch next level if near the end of sublevels
    if (fetchNextLevel) {
      await _listByLevel(nextLevel);
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
  final ytService = ref.read(youtubeServiceProvider);
  return SublevelController(
      subLevelAPI: subLevelAPI, userController: userController, ytService: ytService);
});
