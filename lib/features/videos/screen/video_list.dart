import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/yt_shorts_list.dart';
import '../video_controller.dart';

class VideoListScreen extends ConsumerStatefulWidget {
  const VideoListScreen({super.key});

  @override
  ConsumerState<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends ConsumerState<VideoListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch videos when the screen is initialized
    Future.microtask(() => ref.read(videoControllerProvider.notifier).fetchVideos());
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoControllerProvider);

    switch (videoState.state) {
      case VideoState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );

      case VideoState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                videoState.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(videoControllerProvider.notifier).fetchVideos();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case VideoState.loaded:
        if (videoState.videos.isEmpty) {
          return const Center(
            child: Text('No videos available'),
          );
        }

        // Extract video IDs from the Video objects
        final videoIds = videoState.videos.map((video) => video.id).toList();
        return YoutubeShortsList(videoIds: videoIds);

      case VideoState.initial:
      default:
        return const SizedBox.shrink();
    }
  }
}
