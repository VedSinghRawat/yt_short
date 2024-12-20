import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../video_controller.dart';
import '../../../core/widgets/yt_shorts_list.dart';

class VideoListScreen extends ConsumerStatefulWidget {
  const VideoListScreen({super.key});

  @override
  ConsumerState<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends ConsumerState<VideoListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch videos when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoControllerProvider.notifier).fetchVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoControllerState = ref.watch(videoControllerProvider);

    if (videoControllerState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videoControllerState.videos.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No videos available'),
        ),
      );
    }

    // Map Video objects to their IDs
    final ytIds = videoControllerState.videos.map((video) => video.ytId.toString()).toList();

    return YoutubeShortsList(
      ytIds: ytIds,
    );
  }
}
