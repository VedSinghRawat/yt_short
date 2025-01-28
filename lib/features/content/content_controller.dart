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
  final Map<int, Set<String>> contentKeysByLevel;
  final bool loading;

  ContentControllerState({
    this.contentMap = const {},
    this.contentKeysByLevel = const {},
    this.loading = false,
  });

  ContentControllerState copyWith({
    Map<String, Content>? contentMap,
    Map<int, Set<String>>? contentKeysByLevel,
    bool? loading,
  }) {
    return ContentControllerState(
      contentMap: contentMap ?? this.contentMap,
      contentKeysByLevel: contentKeysByLevel ?? this.contentKeysByLevel,
      loading: loading ?? this.loading,
    );
  }
}

class ContentController extends StateNotifier<ContentControllerState> {
  final UserControllerState userController;
  final IContentAPI contentAPI;

  ContentController({required this.userController, required this.contentAPI}) : super(ContentControllerState());

  Future<List<Content>> _listByLevel(int level) async {
    state = state.copyWith(loading: true);

    List<Content> contents = [];
    try {
      final tempContents = await contentAPI.listByLevel(level);
      Map<String, Content> contentMap = {};
      Map<int, Set<String>> contentKeysByLevel = {};
      for (var content in tempContents) {
        final level = content.speechExercise?.level ?? content.video?.level;
        final subLevel = content.speechExercise?.subLevel ?? content.video?.subLevel;

        contentMap["$level-$subLevel"] = content;
        contentKeysByLevel[level!] = contentKeysByLevel[level] ?? {}
          ..add("$level-$subLevel");
      }

      state = state.copyWith(
        contentMap: contentMap,
        contentKeysByLevel: contentKeysByLevel,
      );
    } catch (e, stackTrace) {
      developer.log('Error in ContentController.fetchVideos', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);
    return contents;
  }

  Future<List<Content>> fetchContents() async {
    var progress = await SharedPref.getCurrProgress();
    final currUserLevel = progress?['level'] ?? userController.currentUser?.level ?? 1;
    final currUserSubLevel = progress?['subLevel'] ?? userController.currentUser?.subLevel ?? 1;

    if (!state.contentKeysByLevel.containsKey(currUserLevel)) {
      await _listByLevel(currUserLevel);
    }

    final currLevelKeys = state.contentKeysByLevel[currUserLevel]!;
    final prevLevel = currUserLevel - 1;
    if ((currUserSubLevel <= kSubLevelAPIBuffer) && !state.contentKeysByLevel.containsKey(prevLevel)) {
      await _listByLevel(prevLevel);
    }

    final nextLevel = currUserLevel + 1;
    if ((currUserSubLevel >= currLevelKeys.length - kSubLevelAPIBuffer) && !state.contentKeysByLevel.containsKey(nextLevel)) {
      await _listByLevel(nextLevel);
    }

    return [];
  }
}

final contentControllerProvider = StateNotifierProvider<ContentController, ContentControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final contentAPI = ref.read(contentAPIProvider);
  return ContentController(contentAPI: contentAPI, userController: userController);
});
