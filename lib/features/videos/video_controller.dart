import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../apis/video_api.dart';
import '../../models/models.dart';

// Define the state for videos
enum VideoState { initial, loading, loaded, error }

// Define the state class to hold both the state enum and the video data
class VideoControllerState {
  final VideoState state;
  final List<Video> videos;
  final String? errorMessage;

  const VideoControllerState({
    required this.state,
    this.videos = const [],
    this.errorMessage,
  });

  VideoControllerState copyWith({
    VideoState? state,
    List<Video>? videos,
    String? errorMessage,
  }) {
    return VideoControllerState(
      state: state ?? this.state,
      videos: videos ?? this.videos,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final videoControllerProvider = StateNotifierProvider<VideoController, VideoControllerState>((ref) {
  return VideoController(ref);
});

class VideoController extends StateNotifier<VideoControllerState> {
  final Ref _ref;

  VideoController(this._ref) : super(const VideoControllerState(state: VideoState.initial));

  Future<void> fetchVideos() async {
    try {
      state = state.copyWith(state: VideoState.loading);

      final videoAPI = _ref.read(videoAPIProvider);
      final videos = await videoAPI.getVideos();

      state = state.copyWith(
        state: VideoState.loaded,
        videos: videos,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      developer.log('Error in VideoController.fetchVideos', error: e.toString(), stackTrace: stackTrace);
      state = state.copyWith(
        state: VideoState.error,
        errorMessage: e.toString(),
      );
      rethrow; // Rethrow to let UI handle the error
    }
  }
}
