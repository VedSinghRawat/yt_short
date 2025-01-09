import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;
import '../../apis/sub_leve_api.dart';
import '../../models/models.dart';

class SubLevelControllerState {
  final List<SubLevel> subLevels;
  final bool loading;

  SubLevelControllerState({
    this.subLevels = const [],
    this.loading = false,
  });

  SubLevelControllerState copyWith({
    List<SubLevel>? subLevels,
    bool? loading,
  }) {
    return SubLevelControllerState(
      subLevels: subLevels ?? this.subLevels,
      loading: loading ?? this.loading,
    );
  }
}

class SubLevelController extends StateNotifier<SubLevelControllerState> {
  final UserControllerState userController;
  final ISubLevelAPI subLevelAPI;

  SubLevelController({required this.userController, required this.subLevelAPI}) : super(SubLevelControllerState());

  Future<void> fetchSubLevels() async {
    state = state.copyWith(loading: true);

    try {
      final user = userController.currentUser;

      final subLevels = await subLevelAPI.getSubLevels(startFromVideoId: user?.atStepId);
      state = state.copyWith(
          subLevels: subLevels
              .map((subLevel) => subLevel is Video
                  ? SubLevel(video: subLevel)
                  : subLevel is SpeechExercise
                      ? SubLevel(speechExercise: subLevel)
                      : null)
              .where((subLevel) => subLevel != null)
              .map((subLevel) => subLevel!)
              .toList());
    } catch (e, stackTrace) {
      developer.log('Error in SubLevelController.fetchVideos', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);
  }
}

final subLevelControllerProvider = StateNotifierProvider<SubLevelController, SubLevelControllerState>((ref) {
  final userController = ref.read(userControllerProvider);
  final subLevelAPI = ref.read(subLevelAPIProvider);
  return SubLevelController(subLevelAPI: subLevelAPI, userController: userController);
});
