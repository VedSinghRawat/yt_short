import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../apis/video_api.dart';
import '../../models/models.dart';

class VideoControllerState {
  final List<Video> videos;
  final bool loading;
  final int? lastViewedVideoId;

  VideoControllerState({
    this.videos = const [],
    this.loading = false,
    this.lastViewedVideoId,
  });

  VideoControllerState copyWith({
    List<Video>? videos,
    bool? loading,
    int? lastViewedVideoId,
  }) {
    return VideoControllerState(
      videos: videos ?? this.videos,
      loading: loading ?? this.loading,
      lastViewedVideoId: lastViewedVideoId ?? this.lastViewedVideoId,
    );
  }
}

class VideoController extends StateNotifier<VideoControllerState> {
  final Ref _ref;

  VideoController(this._ref) : super(VideoControllerState());

  Future<void> fetchVideos() async {
    state = state.copyWith(loading: true);

    try {
      final videoAPI = _ref.read(videoAPIProvider);
      final videos = await videoAPI.getVideos();
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
