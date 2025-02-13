import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/activity_log/activity_log.controller.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/models/content/content.dart';
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
  List<Content>? _cachedContents;

  @override
  void initState() {
    super.initState();
    // Fetch videos when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(contentControllerProvider.notifier).fetchContents();
    });
  }

  void cancelVideoChange(int index, PageController controller) {
    controller.animateToPage(
      index - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      showSnackBar(context, 'Please complete the current content before proceeding');
    } catch (e) {
      log('error in cancelVideoChange: $e');
    }
  }

  void onVideoChange(int index, PageController controller, List<Content> contents) async {
    if (!mounted) return;

    if (contents.length <= index) {
      fetchContent(index, contents);
      return;
    }

    // Get the content, level, and sublevel for the current index
    final content = contents[index];
    final level = (content.speechExercise?.level ?? content.video?.level)!;
    final subLevel = (content.speechExercise?.subLevel ?? content.video?.subLevel)!;

    // Get the user's email, return early if index is out of bounds
    final user = ref.read(userControllerProvider).currentUser;
    final userEmail = user?.email ?? '';

    final hasFinishedVideo = ref.read(contentControllerProvider).hasFinishedVideo;
    final localProgress = await SharedPref.getCurrProgress();

    final levelAfter = localProgress == null ||
        isLevelAfter(level, subLevel, getMax([user?.maxLevel, localProgress['maxLevel']]).toInt(),
            getMax([user?.maxSubLevel, localProgress['maxSubLevel']]).toInt());

    if (!hasFinishedVideo && levelAfter) {
      cancelVideoChange(index, controller);
      return;
    }

    ref.read(contentControllerProvider.notifier).setHasFinishedVideo(false);

    // If the level requires auth and the user is not logged in, redirect to sign in
    if (level > kAuthRequiredLevel && userEmail.isEmpty && mounted) {
      context.go(Routes.signIn);
    }

    final isLocalLevelAfter = isLevelAfter(
        level, subLevel, localProgress?['maxLevel'] ?? 0, localProgress?['maxSubLevel'] ?? 0);

    // Update the user's current progress in shared preferences
    await SharedPref.setCurrProgress(
        level: level,
        subLevel: subLevel,
        maxLevel: isLocalLevelAfter ? level : localProgress?['maxLevel'],
        maxSubLevel: isLocalLevelAfter ? subLevel : localProgress?['maxSubLevel']);

    await fetchContent(index, contents);

    // If the user is logged in, add an activity log entry
    if (userEmail.isNotEmpty) {
      await SharedPref.addActivityLog(ActivityLog(
        subLevel: subLevel,
        level: level,
        userEmail: userEmail,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    // Sync the progress with db if the user moves to a new level
    syncProgress(index, contents, userEmail, level, subLevel);

    // Sync the last sync time with the server
    syncLastSyncToServer();
  }

  Future<void> fetchContent(int index, List<Content> contents) async {
    if (index <= kSubLevelAPIBuffer || index >= contents.length - kSubLevelAPIBuffer) {
      await ref.read(contentControllerProvider.notifier).fetchContents();
    }
  }

  Future<void> syncProgress(
      int index, List<Content> contents, String userEmail, int level, int subLevel) async {
    if (index > 0) {
      final previousContentLevel =
          contents[index - 1].speechExercise?.level ?? contents[index - 1].video?.level;

      if (userEmail.isNotEmpty && level != previousContentLevel) {
        ref.read(userControllerProvider.notifier).progressSync(level, subLevel);
      }
    }
  }

  void syncLastSyncToServer() async {
    // Check if enough time has passed since the last sync
    final lastSync = await SharedPref.getLastSync();

    final now = DateTime.now().millisecondsSinceEpoch;

    final diff = now - lastSync;

    if (diff < kMinProgressSyncingDiffInMillis) return;

    // If the user is logged in, sync their progress with the server
    // Sync any pending activity logs with the server
    final activityLogs = await SharedPref.getActivityLogs();

    if (activityLogs == null || activityLogs.isEmpty) return;

    await ref.read(activityLogControllerProvider.notifier).syncActivityLogs(activityLogs);

    // Clear the activity logs and update the last sync time
    await SharedPref.clearActivityLogs();
    await SharedPref.setLastSync(DateTime.now().millisecondsSinceEpoch);
  }

  List<Content> _getSortedContents(Map<String, Content> contentMap) {
    final contents = contentMap.values.toList();
    contents.sort((a, b) {
      final levelA = a.speechExercise?.level ?? a.video?.level ?? 0;
      final levelB = b.speechExercise?.level ?? b.video?.level ?? 0;

      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      }

      final subLevelA = a.speechExercise?.subLevel ?? a.video?.subLevel ?? 0;
      final subLevelB = b.speechExercise?.subLevel ?? b.video?.subLevel ?? 0;

      return subLevelA.compareTo(subLevelB);
    });
    return contents;
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(contentControllerProvider);
    final loading = provider.loading;
    final contentMap = provider.contentMap;

    final isLoggedIn =
        ref.watch(userControllerProvider.select((state) => state.currentUser))?.email.isNotEmpty ??
            false;

    // Only sort contents if they have changed
    if (_cachedContents == null || !listEquals(_cachedContents, contentMap.values.toList())) {
      _cachedContents = _getSortedContents(contentMap);
    }

    if (loading && _cachedContents!.isEmpty) {
      return const Loader();
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
        contents: _cachedContents!,
        onVideoChange: (int index, PageController controller) async =>
            onVideoChange(index, controller, _cachedContents!),
      ),
    );
  }
}
