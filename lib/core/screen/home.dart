import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import '../../features/content/content_controller.dart';
import '../../features/content/widget/content_list.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final progress = await SharedPref.getProgress();
      await ref.read(contentControllerProvider.notifier).fetchContents(level: progress?['level']);
    });
  }

  Future<void> _handleOnScroll(int index) async {
    final contents = ref.read(contentControllerProvider).contents;
    if (index < 0 || index >= contents.length) return;

    final content = contents[index];
    final level = (content.speechExercise?.level ?? content.video?.level)!;
    final subLevel = (content.speechExercise?.subLevel ?? content.video?.subLevel)!;

    await SharedPref.setProgress(level, subLevel);

    const minDiff = Duration.microsecondsPerMinute * 10;
    final lastSync = await SharedPref.getLastSync();
    final now = DateTime.now().millisecondsSinceEpoch;

    if ((now - lastSync) < minDiff) return;

    await ref.read(userControllerProvider.notifier).progressSync(level, subLevel);
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
