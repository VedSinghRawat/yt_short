import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
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

  final bool loading;

  ContentControllerState({
    this.contentMap = const {},
    this.subLevelCountByLevel = const {},
    this.loading = false,
  });

  ContentControllerState copyWith({
    Map<String, Content>? contentMap,
    Map<int, int>? subLevelCountByLevel,
    bool? loading,
  }) {
    return ContentControllerState(
      contentMap: contentMap ?? this.contentMap,
      subLevelCountByLevel: subLevelCountByLevel ?? this.subLevelCountByLevel,
      loading: loading ?? this.loading,
    );
  }
}

class ContentController extends StateNotifier<ContentControllerState> {
  final UserControllerState userController;
  final IContentAPI contentAPI;

  ContentController({required this.userController, required this.contentAPI})
      : super(ContentControllerState());

  Future<List<Content>> _listByLevel(int level) async {
    if (state.subLevelCountByLevel.containsKey(level)) return [];

    state = state.copyWith(loading: true);
    try {
      final tempContents = await contentAPI.listByLevel(level);
      Map<String, Content> contentMap = Map.from(state.contentMap);
      Map<int, int> subLevelCountByLevel = Map.from(state.subLevelCountByLevel);

      subLevelCountByLevel[level] = tempContents.length;
      for (var content in tempContents) {
        final level = content.speechExercise?.level ?? content.video?.level;
        final subLevel = content.speechExercise?.subLevel ?? content.video?.subLevel;
        contentMap["$level-$subLevel"] = content;
      }

      state = state.copyWith(
        contentMap: contentMap,
        subLevelCountByLevel: subLevelCountByLevel,
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
    if (state.loading) return;

    final progress = await SharedPref.getCurrProgress();

    final currUserLevel = progress?['level'] ?? userController.currentUser?.level ?? 1;
    final currUserSubLevel = progress?['subLevel'] ?? userController.currentUser?.subLevel ?? 1;

    // Fetch the current level if not already in cache
    if (!state.subLevelCountByLevel.containsKey(currUserLevel)) {
      await _listByLevel(currUserLevel);
    }

    // Fetch previous level if near start of sublevels
    final prevLevel = currUserLevel - 1;

    if (currUserSubLevel <= kSubLevelAPIBuffer &&
        prevLevel >= 1 &&
        !state.subLevelCountByLevel.containsKey(prevLevel)) {
      await _listByLevel(prevLevel);
    }

    // Fetch next level if near the end of sublevels
    final currLevelKeys = state.subLevelCountByLevel[currUserLevel] ?? 0;
    final nextLevel = currUserLevel + 1;

    if (currUserSubLevel >= currLevelKeys - kSubLevelAPIBuffer &&
        !state.subLevelCountByLevel.containsKey(nextLevel)) {
      await _listByLevel(nextLevel);
    }
  }
}

final contentControllerProvider =
    StateNotifierProvider<ContentController, ContentControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final contentAPI = ref.read(contentAPIProvider);
  return ContentController(contentAPI: contentAPI, userController: userController);
});
