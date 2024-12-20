import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;
import '../../apis/video_api.dart';
import '../../models/models.dart';

class VideoControllerState {
  final List<Video> videos;
  final bool loading;

  VideoControllerState({
    this.videos = const [],
    this.loading = false,
  });

  VideoControllerState copyWith({
    List<Video>? videos,
    bool? loading,
  }) {
    return VideoControllerState(
      videos: videos ?? this.videos,
      loading: loading ?? this.loading,
    );
  }
}

class VideoController extends StateNotifier<VideoControllerState> {
  final Ref _ref;
  late UserControllerState userController;

  VideoController(this._ref) : super(VideoControllerState()) {
    userController = _ref.watch(userControllerProvider);
  }

  Future<void> fetchVideos() async {
    state = state.copyWith(loading: true);

    try {
      final videoAPI = _ref.read(videoAPIProvider);
      final user = userController.currentUser;

      final videos = await videoAPI.getVideos(startFromVideoId: user?.atVidId);
      state = state.copyWith(videos: videos);
    } catch (e, stackTrace) {
      developer.log('Error in VideoController.fetchVideos', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);
  }
}

final videoControllerProvider = StateNotifierProvider<VideoController, VideoControllerState>((ref) {
  return VideoController(ref);
});
