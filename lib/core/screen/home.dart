import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/activity_log/activity_log.controller.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import '../../features/content/content_controller.dart';
import '../../features/content/widget/content_list.dart';
import '../widgets/custom_app_bar.dart';
import '../../features/user/user_controller.dart';
import '../../features/auth/auth_controller.dart';
import 'dart:developer' as developer;

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
      await ref.read(contentControllerProvider.notifier).fetchContents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(contentControllerProvider);
    final loading = provider.loading;
    final contentMap = provider.contentMap;

    final isLoggedIn =
        ref.watch(userControllerProvider.select((state) => state.currentUser))?.email.isNotEmpty ??
            false;
    final contents = contentMap.values.toList()
      ..sort((a, b) {
        final levelA = a.speechExercise?.level ?? a.video?.level ?? 0;
        final levelB = b.speechExercise?.level ?? b.video?.level ?? 0;

        if (levelA != levelB) {
          return levelA.compareTo(levelB);
        }

        final subLevelA = a.speechExercise?.subLevel ?? a.video?.subLevel ?? 0;
        final subLevelB = b.speechExercise?.subLevel ?? b.video?.subLevel ?? 0;

        return subLevelA.compareTo(subLevelB);
      });

    if (loading && contents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Learn English',
        actions: [
          !isLoggedIn
              ? IconButton(
                  onPressed: () {
                    context.push(Routes.signIn);
                  },
                  icon: const Icon(Icons.account_circle),
                )
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    if (value == 'signout') {
                      ref.read(authControllerProvider.notifier).signOut(context);
                      context.go(Routes.signIn);
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
        contents: contents,
        onVideoChange: (int index) async {
          // Get the user's email, return early if index is out of bounds
          if (index <= kSubLevelAPIBuffer || index >= contents.length - kSubLevelAPIBuffer) {
            await ref.read(contentControllerProvider.notifier).fetchContents();
          }

          if (index < 0 || index >= contents.length) return;
          final userEmail = ref.read(userControllerProvider).currentUser?.email ?? '';

          // Get the content, level, and sublevel for the current index
          final content = contents[index];
          final level = (content.speechExercise?.level ?? content.video?.level)!;
          final subLevel = (content.speechExercise?.subLevel ?? content.video?.subLevel)!;

          final previousLevel =
              contents[index - 1].speechExercise?.level ?? contents[index - 1].video?.level;

          // Update the user's current progress in shared preferences
          await SharedPref.setCurrProgress(level, subLevel);

          // If the level requires auth and the user is not logged in, redirect to sign in
          if (level > kAuthRequiredLevel && userEmail.isEmpty && context.mounted) {
            context.go(Routes.signIn);
          }

          // If the user is logged in, add an activity log entry
          if (userEmail.isNotEmpty) {
            await SharedPref.addActivityLog(ActivityLog(
              subLevel: subLevel,
              level: level,
              userEmail: userEmail,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ));
          }

          if (userEmail.isNotEmpty && level != previousLevel) {
            await ref.read(userControllerProvider.notifier).progressSync(level, subLevel);
          }

          // Check if enough time has passed since the last sync
          const minDiff = Duration.millisecondsPerMinute * 10;
          final lastSync = await SharedPref.getLastSync();
          final now = DateTime.now().millisecondsSinceEpoch;
          final diff = now - lastSync;

          if (diff < minDiff) return;

          // If the user is logged in, sync their progress with the server
          if (userEmail.isNotEmpty) {
            await ref.read(userControllerProvider.notifier).progressSync(level, subLevel);
          }
          // If the user is logged in, sync their progress with the server
          // Sync any pending activity logs with the server
          final activityLogs = await SharedPref.getActivityLogs();
          if (activityLogs == null || activityLogs.isEmpty) return;
          await ref.read(activityLogControllerProvider.notifier).syncActivityLogs(activityLogs);

          // Clear the activity logs and update the last sync time
          await SharedPref.clearActivityLogs();
          await SharedPref.setLastSync(DateTime.now().millisecondsSinceEpoch);
        },
      ),
    );
  }
}
