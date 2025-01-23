import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/content/content_controller.dart';
import '../../features/content/widget/sub_level_list.dart';
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
      ref.read(contentControllerProvider.notifier).fetchContents();
    });
  }

  void _handleOnScroll(int index) {
    final contents = ref.read(contentControllerProvider).contents;
    if (index >= 0 && index < contents.length) {
      final content = contents[index];
      final level = (content.speechExercise?.level ?? content.video?.level)!;
      final subLevel = (content.speechExercise?.subLevel ?? content.video?.subLevel)!;
      // ref.read(userControllerProvider.notifier).updateLastViewedVideo(level, subLevel, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentControllerState = ref.watch(contentControllerProvider);

    if (contentControllerState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contentControllerState.contents.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No videos available'),
        ),
      );
    }

    // Map Video objects to their IDs

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learn English',
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
      body: ContentsList(
        stepList: contentControllerState.contents,
        onVideoChange: _handleOnScroll,
      ),
    );
  }
}
