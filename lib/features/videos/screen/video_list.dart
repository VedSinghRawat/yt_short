import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../video_controller.dart';
import '../../../core/widgets/yt_shorts_list.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../user/user_controller.dart';
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
    // Fetch videos when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(videoControllerProvider.notifier).fetchVideos();
    });
  }

  void _handleVideoChange(int index) {
    final videos = ref.read(videoControllerProvider).videos;
    if (index >= 0 && index < videos.length) {
      final videoId = videos[index].id;
      ref.read(userControllerProvider.notifier).updateLastViewedVideo(videoId, context);
    }
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

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Youtube Shorts',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'signout') {
                ref.read(authControllerProvider.notifier).signOut(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: YoutubeShortsList(
        ytIds: ytIds,
        onVideoChange: _handleVideoChange,
      ),
    );
  }
}
