import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/screen/app_bar.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/activity_log/activity_log.controller.dart';
import 'package:myapp/models/content/content.dart';
import '../../features/content/content_controller.dart';
import '../../features/content/widget/content_list.dart';
import '../../features/user/user_controller.dart';
import 'dart:developer' as developer;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(contentControllerProvider.notifier).fetchContents();
    });
  }

  Future<bool> cancelVideoChange(
    int index,
    PageController controller,
    int maxLevel,
    int maxSubLevel,
    int level,
    int subLevel,
    bool hasLocalProgress,
    bool isAdmin,
  ) async {
    // Inline the logic from _canChangeVideo
    final hasFinishedVideo = ref.read(contentControllerProvider).hasFinishedVideo;
    final levelAfter = !hasLocalProgress || isLevelAfter(level, subLevel, maxLevel, maxSubLevel);
    final canChangeVideo = hasFinishedVideo || !levelAfter;

    if (canChangeVideo || isAdmin) {
      return false;
    }

    controller.animateToPage(
      index - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    try {
      showSnackBar(context, 'Please complete the current content before proceeding');
    } catch (e) {
      developer.log('error in cancelVideoChange: $e');
    }

    return true;
  }

  Future<bool> handleFetchContents(int index, List<Content> contents) async {
    if (index < _cachedContents!.length) return false;
    await ref.read(contentControllerProvider.notifier).fetchContents();

    return true;
  }

  Future<void> syncProgress(
    int index,
    List<Content> contents,
    String userEmail,
    int level,
    int subLevel,
  ) async {
    if (index <= 0) return;

    final previousContentLevel = contents[index - 1].level;

    if (userEmail.isNotEmpty && level != previousContentLevel) {
      ref.read(userControllerProvider.notifier).progressSync(level, subLevel);
    }
  }

  Future<void> syncActivityLogs() async {
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

  Future<void> syncLocalProgress(
      int level, int subLevel, int localMaxLevel, int localMaxSubLevel) async {
    final isLocalLevelAfter = isLevelAfter(level, subLevel, localMaxLevel, localMaxSubLevel);

    // Update the user's current progress in shared preferences
    await SharedPref.setCurrProgress(
      level: level,
      subLevel: subLevel,
      maxLevel: isLocalLevelAfter ? level : localMaxLevel,
      maxSubLevel: isLocalLevelAfter ? subLevel : localMaxSubLevel,
    );
  }

  Future<void> onVideoChange(int index, PageController controller) async {
    if (!mounted || _cachedContents == null) return;

    // If the index is greater than the length of the cached contents, fetch the contents and return
    if (await handleFetchContents(index, _cachedContents!)) return;

    // Get the content, level, and sublevel for the current index
    final content = _cachedContents![index];
    final level = content.level;
    final subLevel = content.subLevel;

    // Get the user's email
    final user = ref.read(userControllerProvider).currentUser;

    final localProgress = await SharedPref.getCurrProgress();
    final localMaxLevel = localProgress?['maxLevel'] ?? 0;
    final localMaxSubLevel = localProgress?['maxSubLevel'] ?? 0;

    // Check if video change should be cancelled
    if (await cancelVideoChange(
      index,
      controller,
      max(user?.maxLevel ?? 0, localMaxLevel),
      max(user?.maxSubLevel ?? 0, localMaxSubLevel),
      level,
      subLevel,
      localProgress != null,
      user?.isAdmin == true,
    )) {
      return;
    }

    ref.read(contentControllerProvider.notifier).setHasFinishedVideo(false);

    final userEmail = user?.email ?? '';

    // Sync the local progress
    await syncLocalProgress(level, subLevel, localMaxLevel, localMaxSubLevel);

    // If the level requires auth and the user is not logged in, redirect to sign in
    if (level > kAuthRequiredLevel && userEmail.isEmpty && mounted) {
      context.go(Routes.signIn);
      return;
    }

    // Fetch the contents if needed
    await handleFetchContents(index, _cachedContents!);

    // If the user is logged in, add an activity log entry
    await SharedPref.addActivityLog(level, subLevel, userEmail);

    // Sync the progress with db if the user moves to a new level
    await syncProgress(index, _cachedContents!, userEmail, level, subLevel);

    // Sync the last sync time with the server
    await syncActivityLogs();
  }

  List<Content> _getSortedContents(Map<String, Content> contentMap) {
    final contents = contentMap.values.toList();
    contents.sort((a, b) {
      final levelA = a.level;
      final levelB = b.level;

      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      }

      final subLevelA = a.subLevel;
      final subLevelB = b.subLevel;

      return subLevelA.compareTo(subLevelB);
    });
    return contents;
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(contentControllerProvider.select((state) => state.loading));
    final contentMap = ref.watch(contentControllerProvider.select((state) => state.contentMap));
    final ytUrls = ref.watch(contentControllerProvider.select((state) => state.ytUrls));

    // Only sort contents if they have changed
    if (_cachedContents == null || !listEquals(_cachedContents, contentMap.values.toList())) {
      _cachedContents = _getSortedContents(contentMap);
    }

    if (loading != false && _cachedContents!.isEmpty) {
      return const Loader();
    }

    return Scaffold(
      appBar: const HomeScreenAppBar(),
      body: ContentsList(
        isLoading: loading ?? false,
        contents: _cachedContents!,
        onVideoChange: onVideoChange,
        ytUrls: ytUrls,
      ),
    );
  }
}
