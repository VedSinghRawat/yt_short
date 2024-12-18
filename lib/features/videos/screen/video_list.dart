import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/yt_shorts_list.dart';
import '../video_controller.dart';
import '../../auth/auth_controller.dart';

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
    Future.microtask(() {
      if (mounted) {
        ref.read(videoControllerProvider.notifier).fetchVideos(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoControllerProvider);
    final authController = ref.watch(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Youtube Shorts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authController.signOut(context);
            },
          ),
        ],
      ),
      body: _buildBody(videoState),
    );
  }

  Widget _buildBody(VideoControllerState videoState) {
    switch (videoState.state) {
      case VideoState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );

      case VideoState.loaded:
        if (videoState.videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No videos available'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(videoControllerProvider.notifier).fetchVideos(context);
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
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
