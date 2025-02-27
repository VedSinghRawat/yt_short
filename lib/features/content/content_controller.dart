import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/youtube_service.dart';
import 'package:myapp/core/shared_pref.dart';
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

  Future<List<Content>> _listByLevel(int level) async {
    if (state.subLevelCountByLevel.containsKey(level) || state.loading == true) return [];

    state = state.copyWith(loading: true);
    try {
      final tempContents = await contentAPI.listByLevel(level);
      Map<String, Content> contentMap = Map.from(state.contentMap);
      Map<int, int> subLevelCountByLevel = Map.from(state.subLevelCountByLevel);

      developer.log('fetching level: $level');
      final startTime = DateTime.now();

      final ytUrls = await ytService.listMediaVideoUrls(tempContents.map((e) => e.ytId).toList());

      developer.log('ytUrls: ${ytUrls.length}');
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      developer.log('Duration: $duration');

      subLevelCountByLevel[level] = tempContents.length;
      for (var content in tempContents) {
        contentMap["${content.level}-${content.subLevel}"] = content;
      }

      state = state.copyWith(
        contentMap: contentMap,
        subLevelCountByLevel: subLevelCountByLevel,
        ytUrls: {...state.ytUrls, ...ytUrls},
      );
    } catch (e, stackTrace) {
      developer.log('Error in ContentController._listByLevel',
          error: e.toString(), stackTrace: stackTrace);
    } finally {
      state = state.copyWith(loading: false);
    }
    return [];
  }

  Future<void> fetchContents() async {
    final progress = await SharedPref.getCurrProgress();

    final currUserLevel = progress?['level'] ?? userController.currentUser?.level ?? 1;
    final currUserSubLevel = progress?['subLevel'] ?? userController.currentUser?.subLevel ?? 1;

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
