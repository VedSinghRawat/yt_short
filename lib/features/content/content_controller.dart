import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;
import '../../apis/content_api.dart';
import '../../models/models.dart';

class ContentControllerState {
  final List<Content> contents;
  final bool loading;

  ContentControllerState({
    this.contents = const [],
    this.loading = false,
  });

  ContentControllerState copyWith({
    List<Content>? contents,
    bool? loading,
  }) {
    return ContentControllerState(
      contents: contents ?? this.contents,
      loading: loading ?? this.loading,
    );
  }
}

class ContentController extends StateNotifier<ContentControllerState> {
  final UserControllerState userController;
  final IContentAPI contentAPI;

  ContentController({required this.userController, required this.contentAPI}) : super(ContentControllerState());

  Future<void> fetchContents() async {
    state = state.copyWith(loading: true);

    try {
      final user = userController.currentUser;

      final contents = await contentAPI.getContents(currentLevel: user?.level);
      state = state.copyWith(
        contents: contents
            .map((content) => content is Video
                ? Content(video: content)
                : content is SpeechExercise
                    ? Content(speechExercise: content)
                    : null)
            .where((content) => content != null)
            .map((content) => content!)
            .toList(),
      );
    } catch (e, stackTrace) {
      developer.log('Error in ContentController.fetchVideos', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);
  }
}

final contentControllerProvider = StateNotifierProvider<ContentController, ContentControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final contentAPI = ref.read(contentAPIProvider);
  return ContentController(contentAPI: contentAPI, userController: userController);
});
