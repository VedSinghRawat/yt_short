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
import 'package:myapp/models/sublevel/sublevel.dart';
import '../../features/sublevel/sublevel_controller.dart';
import '../../features/sublevel/widget/sublevel_list.dart';
import '../../features/user/user_controller.dart';
import 'dart:developer' as developer;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Sublevel>? _cachedSublevels;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(sublevelControllerProvider.notifier).fetchSublevels();
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
    final hasFinishedVideo = ref.read(sublevelControllerProvider).hasFinishedVideo;
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
      showSnackBar(context, 'Please complete the current sublevel before proceeding');
    } catch (e) {
      developer.log('error in cancelVideoChange: $e');
    }

    return true;
  }

  Future<bool> handleFetchSublevels(int index, List<Sublevel> sublevels) async {
    if (index < _cachedSublevels!.length) return false;
    await ref.read(sublevelControllerProvider.notifier).fetchSublevels();

    return true;
  }

  Future<void> syncProgress(
    int index,
    List<Sublevel> sublevels,
    String userEmail,
    int level,
    int subLevel,
  ) async {
    if (index <= 0) return;

    final previousSublevelLevel = sublevels[index - 1].level;

    if (userEmail.isNotEmpty && level != previousSublevelLevel) {
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
    if (!mounted || _cachedSublevels == null) return;

    // If the index is greater than the length of the cached sublevels, fetch the sublevels and return
    if (await handleFetchSublevels(index, _cachedSublevels!)) return;

    // Get the sublevel, level, and sublevel for the current index
    final sublevel = _cachedSublevels![index];
    final level = sublevel.level;
    final subLevel = sublevel.subLevel;

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

    ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(false);

    final userEmail = user?.email ?? '';

    // Sync the local progress
    await syncLocalProgress(level, subLevel, localMaxLevel, localMaxSubLevel);

    // If the level requires auth and the user is not logged in, redirect to sign in
    if (level > kAuthRequiredLevel && userEmail.isEmpty && mounted) {
      context.go(Routes.signIn);
      return;
    }

    // Fetch the sublevels if needed
    await handleFetchSublevels(index, _cachedSublevels!);

    // If the user is logged in, add an activity log entry
    await SharedPref.addActivityLog(level, subLevel, userEmail);

    // Sync the progress with db if the user moves to a new level
    await syncProgress(index, _cachedSublevels!, userEmail, level, subLevel);

    // Sync the last sync time with the server
    await syncActivityLogs();
  }

  List<Sublevel> _getSortedSublevels(Map<String, Sublevel> sublevelMap) {
    final sublevels = sublevelMap.values.toList();
    sublevels.sort((a, b) {
      final levelA = a.level;
      final levelB = b.level;

      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      }

      final subLevelA = a.subLevel;
      final subLevelB = b.subLevel;

      return subLevelA.compareTo(subLevelB);
    });
    return sublevels;
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(sublevelControllerProvider.select((state) => state.loading));
    final sublevelMap = ref.watch(sublevelControllerProvider.select((state) => state.sublevelMap));
    final ytUrls = ref.watch(sublevelControllerProvider.select((state) => state.ytUrls));

    // Only sort sublevels if they have changed
    if (_cachedSublevels == null || !listEquals(_cachedSublevels, sublevelMap.values.toList())) {
      _cachedSublevels = _getSortedSublevels(sublevelMap);
    }

    if (loading != false && _cachedSublevels!.isEmpty) {
      return const Loader();
    }

    return Scaffold(
      appBar: const HomeScreenAppBar(),
      body: SublevelsList(
        isLoading: loading ?? false,
        sublevels: _cachedSublevels!,
        onVideoChange: onVideoChange,
        ytUrls: ytUrls,
      ),
    );
  }
}
