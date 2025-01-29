import 'package:flutter/foundation.dart';
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
  final Map<int, List<String>> contentKeysByLevel;
  // the content keys (level-subLevel) to show in the home screen
  final List<int> levelsToShow;
  final bool loading;

  ContentControllerState({
    this.contentMap = const {},
    this.contentKeysByLevel = const {},
    this.levelsToShow = const [],
    this.loading = false,
  });

  ContentControllerState copyWith({
    Map<String, Content>? contentMap,
    Map<int, List<String>>? contentKeysByLevel,
    List<int>? levelsToShow,
    bool? loading,
  }) {
    return ContentControllerState(
      contentMap: contentMap ?? this.contentMap,
      contentKeysByLevel: contentKeysByLevel ?? this.contentKeysByLevel,
      levelsToShow: levelsToShow ?? this.levelsToShow,
      loading: loading ?? this.loading,
    );
  }
}

class ContentController extends StateNotifier<ContentControllerState> {
  final UserControllerState userController;
  final IContentAPI contentAPI;

  ContentController({required this.userController, required this.contentAPI}) : super(ContentControllerState());

  Future<List<Content>> _listByLevel(int level) async {
    if (state.contentKeysByLevel.containsKey(level)) return [];

    state = state.copyWith(loading: true);
    try {
      final tempContents = await contentAPI.listByLevel(level);
      Map<String, Content> contentMap = Map.from(state.contentMap);
      Map<int, List<String>> contentKeysByLevel = Map.from(state.contentKeysByLevel);

      for (var content in tempContents) {
        final level = content.speechExercise?.level ?? content.video?.level;
        final subLevel = content.speechExercise?.subLevel ?? content.video?.subLevel;
        contentMap["$level-$subLevel"] = content;
        contentKeysByLevel[level!] = contentKeysByLevel[level] ?? []
          ..add("$level-$subLevel");
      }

      state = state.copyWith(
        contentMap: contentMap,
        contentKeysByLevel: contentKeysByLevel,
      );
    } catch (e, stackTrace) {
      developer.log('Error in ContentController._listByLevel', error: e.toString(), stackTrace: stackTrace);
    } finally {
      state = state.copyWith(loading: false);
    }
    return [];
  }

  Future<void> fetchContents() async {
    if (state.loading) return;

    var progress = await SharedPref.getCurrProgress();
    final currUserLevel = progress?['level'] ?? userController.currentUser?.level ?? 1;
    final currUserSubLevel = progress?['subLevel'] ?? userController.currentUser?.subLevel ?? 1;

    developer.log('fetchContents: $currUserLevel $currUserSubLevel');

    List<int> levelsToShow = [currUserLevel];

    // Fetch the current level if not already in cache
    if (!state.contentKeysByLevel.containsKey(currUserLevel)) {
      await _listByLevel(currUserLevel);
    }

    // Fetch previous level if near start of sublevels
    final prevLevel = currUserLevel - 1;
    if (currUserSubLevel <= kSubLevelAPIBuffer && prevLevel >= 1) {
      if (!state.contentKeysByLevel.containsKey(prevLevel)) {
        await _listByLevel(prevLevel);
      }
      levelsToShow.insert(0, prevLevel);
    }

    // Fetch next level if near the end of sublevels
    final currLevelKeys = state.contentKeysByLevel[currUserLevel] ?? [];
    final nextLevel = currUserLevel + 1;
    if (currUserSubLevel >= currLevelKeys.length - kSubLevelAPIBuffer) {
      if (!state.contentKeysByLevel.containsKey(nextLevel)) {
        await _listByLevel(nextLevel);
      }
      levelsToShow.add(nextLevel);
    }

    // Update levels to show
    if (!listEquals(state.levelsToShow, levelsToShow)) {
      state = state.copyWith(levelsToShow: levelsToShow);
    }
  }
}

final contentControllerProvider = StateNotifierProvider<ContentController, ContentControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final contentAPI = ref.read(contentAPIProvider);
  return ContentController(contentAPI: contentAPI, userController: userController);
});
