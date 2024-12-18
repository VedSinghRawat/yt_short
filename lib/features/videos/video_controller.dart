import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../apis/video_api.dart';
import '../../models/models.dart';
import '../../core/utils.dart';

// Define the state for videos
enum VideoState { initial, loading, loaded }

// Define the state class to hold both the state enum and the video data
class VideoControllerState {
  final VideoState state;
  final List<Video> videos;

  const VideoControllerState({
    required this.state,
    this.videos = const [],
  });

  VideoControllerState copyWith({
    VideoState? state,
    List<Video>? videos,
  }) {
    return VideoControllerState(
      state: state ?? this.state,
      videos: videos ?? this.videos,
    );
  }
}

final videoControllerProvider = StateNotifierProvider<VideoController, VideoControllerState>((ref) {
  return VideoController(ref);
});

class VideoController extends StateNotifier<VideoControllerState> {
  final Ref _ref;

  VideoController(this._ref) : super(const VideoControllerState(state: VideoState.initial));

  Future<void> fetchVideos(BuildContext context) async {
    try {
      state = state.copyWith(state: VideoState.loading);

      final videoAPI = _ref.read(videoAPIProvider);
      final videos = await videoAPI.getVideos();

      state = state.copyWith(
        state: VideoState.loaded,
        videos: videos,
      );
    } catch (e, stackTrace) {
      developer.log('Error in VideoController.fetchVideos', error: e.toString(), stackTrace: stackTrace);
      state = state.copyWith(state: VideoState.loaded); // Reset to loaded state with existing videos
      showErrorSnackBar(context, e.toString());
    }
  }
}
