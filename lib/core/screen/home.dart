import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sub_level/sub_level_controller.dart';
import '../../features/sub_level/widget/sub_level_list.dart';
import '../widgets/custom_app_bar.dart';
import '../../features/user/user_controller.dart';
import '../../features/auth/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch videos when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(subLevelControllerProvider.notifier).fetchSubLevels();
    });
  }

  void _handleOnScroll(int index) {
    final videos = ref.read(subLevelControllerProvider).subLevels;
    if (index >= 0 && index < videos.length) {
      final subLevel = videos[index];
      final videoId = (subLevel.speechExercise?.id ?? subLevel.video?.id)!;
      ref.read(userControllerProvider.notifier).updateLastViewedVideo(videoId, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subLevelControllerState = ref.watch(subLevelControllerProvider);

    if (subLevelControllerState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (subLevelControllerState.subLevels.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No videos available'),
        ),
      );
    }

    // Map Video objects to their IDs

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
      body: SubLevelsList(
        stepList: subLevelControllerState.subLevels,
        onVideoChange: _handleOnScroll,
      ),
    );
  }
}
