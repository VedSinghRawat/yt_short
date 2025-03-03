import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/youtube_service.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;
import '../../apis/content_api.dart';
import '../../models/models.dart';

class ContentControllerState {
  // the key will be $level-$subLevel
  final Map<String, Content> contentMap;
  // level against the key attribute of content
  final Map<int, int> subLevelCountByLevel;
  final bool hasFinishedVideo;
  final Map<String, Map<String, String>> ytUrls;

  final bool? loading;

  ContentControllerState({
    this.contentMap = const {},
    this.subLevelCountByLevel = const {},
    this.loading,
    this.hasFinishedVideo = false,
    this.ytUrls = const {},
  });

  ContentControllerState copyWith({
    Map<String, Content>? contentMap,
    Map<int, int>? subLevelCountByLevel,
    bool? loading,
    bool? hasFinishedVideo,
    Map<String, Map<String, String>>? ytUrls,
  }) {
    return ContentControllerState(
      contentMap: contentMap ?? this.contentMap,
      subLevelCountByLevel: subLevelCountByLevel ?? this.subLevelCountByLevel,
      loading: loading ?? this.loading,
      hasFinishedVideo: hasFinishedVideo ?? this.hasFinishedVideo,
      ytUrls: ytUrls ?? this.ytUrls,
    );
  }
}

class ContentController extends StateNotifier<ContentControllerState> {
  final UserControllerState userController;
  final IContentAPI contentAPI;
  final YoutubeService ytService;

  ContentController({
    required this.userController,
    required this.contentAPI,
    required this.ytService,
  }) : super(ContentControllerState());

  Future<void> _listByLevel(int level) async {
    if (state.subLevelCountByLevel.containsKey(level) || state.loading == true) return;

    state = state.copyWith(loading: true);
    try {
      final tempContents = await contentAPI.listByLevel(level);

      Map<String, Content> contentMap = {...state.contentMap};
      Map<int, int> subLevelCountByLevel = {...state.subLevelCountByLevel};

      await fetchRelavantYturls(tempContents);

      subLevelCountByLevel[level] = tempContents.length;

      for (var content in tempContents) {
        contentMap["${content.level}-${content.subLevel}"] = content;
      }

      state = state.copyWith(
        contentMap: contentMap,
        subLevelCountByLevel: subLevelCountByLevel,
      );

      await fetchYtUrls(tempContents.map((e) => e.ytId).toList());
    } catch (e, stackTrace) {
      developer.log('Error in ContentController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> fetchRelavantYturls(List<Content> tempContents) async {
    final userSubLevel = await userController.subLevel;

    if (state.ytUrls.isNotEmpty) return;

    final relevantSubLevels = {userSubLevel - 1, userSubLevel, userSubLevel + 1};

    final ytIds = tempContents
        .where((e) => relevantSubLevels.contains(e.subLevel))
        .map((e) => e.ytId)
        .toList();

    await fetchYtUrls(ytIds);
  }

  Future<void> fetchYtUrls(List<String> ytIds) async {
    final ytUrls = await compute(ytService.listMediaUrls, ytIds);
    state = state.copyWith(ytUrls: {...state.ytUrls, ...ytUrls});
  }

  Future<void> fetchContents() async {
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

final contentControllerProvider =
    StateNotifierProvider<ContentController, ContentControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final contentAPI = ref.read(contentAPIProvider);
  final ytService = ref.read(youtubeServiceProvider);
  return ContentController(
      contentAPI: contentAPI, userController: userController, ytService: ytService);
});
