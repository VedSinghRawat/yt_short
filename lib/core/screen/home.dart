import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/screen/app_bar.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/activity_log/activity_log.controller.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
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
  List<SubLevel>? _cachedSublevels;

  @override
  void initState() {
    super.initState();

    developer.log('home page');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(sublevelControllerProvider.notifier).handleFetchSublevels();
    });
  }

  bool cancelVideoChange(
    int index,
    int maxLevel,
    int maxSubLevel,
    int level,
    int subLevel,
    bool hasLocalProgress,
    bool isAdmin,
    int doneToday,
  ) {
    if (isAdmin) return false;

    final levelAfter = !hasLocalProgress || isLevelAfter(level, subLevel, maxLevel, maxSubLevel);
    if (!levelAfter) return false;

    final hasFinishedVideo = ref.read(sublevelControllerProvider).hasFinishedVideo;
    if (!hasFinishedVideo) {
      showSnackBar(context, 'Please complete the current sublevel before proceeding');
      return true;
    }

    // Check daily level limit only when changing to a new level
    final bool exceedsDailyLimit = doneToday >= kMaxLevelCompletionsPerDay;
    if (!exceedsDailyLimit) return false;

    showSnackBar(context, 'You can only complete $kMaxLevelCompletionsPerDay levels per day');
    return true;
  }

  Future<bool> handleFetchSublevels(int index) async {
    if (index < _cachedSublevels!.length) return false;
    await ref.read(sublevelControllerProvider.notifier).handleFetchSublevels();

    return true;
  }

  Future<void> syncProgress(
    int index,
    List<SubLevel> sublevels,
    String userEmail,
    int subLevel,
  ) async {
    if (index <= 0) return;

    final previousLevelId = sublevels[index - 1].levelId;
    final levelId = sublevels[index].levelId;
    if (previousLevelId == levelId) return;

    if (userEmail.isNotEmpty) {
      ref.read(userControllerProvider.notifier).sync(levelId, subLevel);
    }
  }

  Future<void> syncActivityLogs() async {
    // Check if enough time has passed since the last sync
    final lastSync = SharedPref.get(PrefKey.lastSync) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastSync;
    Console.log(diff.toString());
    if (diff < kMinProgressSyncingDiffInMillis) return;

    // If the user is logged in, sync their progress with the server
    // Sync any pending activity logs with the server
    final activityLogs = SharedPref.get(PrefKey.activityLogs);

    if (activityLogs == null || activityLogs.isEmpty) return;

    await ref.read(activityLogControllerProvider.notifier).syncActivityLogs(activityLogs);

    // Clear the activity logs and update the last sync time
    await SharedPref.removeValue(PrefKey.activityLogs);

    await SharedPref.store(
      PrefKey.lastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> syncLocalProgress(
    int level,
    int sublevelIndex,
    String levelId,
    int localMaxLevel,
    int localMaxSubLevel,
  ) async {
    final isCurrLevelAfter = isLevelAfter(level, sublevelIndex, localMaxLevel, localMaxSubLevel);

    // Update the user's current progress in shared preferences
    await SharedPref.copyWith(
      PrefKey.currProgress,
      Progress(
        level: level,
        subLevel: sublevelIndex,
        levelId: levelId,
        maxLevel: isCurrLevelAfter ? level : localMaxLevel,
        maxSubLevel: isCurrLevelAfter ? sublevelIndex : localMaxSubLevel,
      ),
    );
  }

  Future<void> onVideoChange(int index, PageController controller) async {
    if (!mounted || _cachedSublevels == null) return;

    // If the index is greater than the length of the cached sublevels, fetch the sublevels and return
    if (await handleFetchSublevels(index)) return;

    // Get the sublevel, level, and sublevel for the current index
    final sublevel = _cachedSublevels![index];
    final level = sublevel.level;
    final sublevelIndex = sublevel.index;

    // Get the user's email
    final user = ref.read(userControllerProvider).currentUser;

    final localProgress = SharedPref.get(PrefKey.currProgress);
    final localMaxLevel = localProgress?.maxLevel ?? 0;
    final localMaxSubLevel = localProgress?.maxSubLevel ?? 0;

    // Check if video change should be cancelled
    if (cancelVideoChange(
      index,
      max(user?.maxLevel ?? 0, localMaxLevel),
      max(user?.maxSubLevel ?? 0, localMaxSubLevel),
      level,
      sublevelIndex,
      localProgress != null,
      user?.isAdmin == true,
      user?.doneToday ?? 0,
    )) {
      controller.animateToPage(
        index - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(false);

    final userEmail = user?.email ?? '';

    // Sync the local progress
    await syncLocalProgress(
      level,
      sublevelIndex,
      sublevel.levelId,
      localMaxLevel,
      localMaxSubLevel,
    );

    // If the level requires auth and the user is not logged in, redirect to sign in
    if (level > kAuthRequiredLevel && userEmail.isEmpty && mounted) {
      context.go(Routes.signIn);
      return;
    }

    // Fetch the sublevels if needed
    await fetchSubLevels(index);

    // If the user is logged in, add an activity log entry
    await SharedPref.pushValue(
      PrefKey.activityLogs,
      ActivityLog(subLevel: sublevelIndex, level: level, userEmail: userEmail),
    );

    // Sync the progress with db if the user moves to a new level
    await syncProgress(index, _cachedSublevels!, userEmail, sublevelIndex);

    // Sync the last sync time with the server
    await syncActivityLogs();
  }

  Future<void> fetchSubLevels(int index) async {
    if (index == 0) return;

    final prevLevel = _cachedSublevels?[index - 1] ?? 0;
    final currLevel = _cachedSublevels?[index] ?? 0;

    if (prevLevel == currLevel) return;

    await ref.read(sublevelControllerProvider.notifier).handleFetchSublevels();
  }

  List<SubLevel> _getSortedSublevels(List<SubLevel> sublevels) {
    return [...sublevels]..sort((a, b) {
        final levelA = a.level;
        final levelB = b.level;

        if (levelA != levelB) {
          return levelA.compareTo(levelB);
        }

        final subLevelA = a.index;
        final subLevelB = b.index;

        return subLevelA.compareTo(subLevelB);
      });
  }

  @override
  Widget build(BuildContext context) {
    final loadingLevelIds =
        ref.watch(sublevelControllerProvider.select((state) => state.loadingLevelIds));

    final sublevels = ref.watch(sublevelControllerProvider.select((state) => state.sublevels));

    // Only sort sublevels if they have changed
    if (_cachedSublevels == null || _cachedSublevels!.length != sublevels.toList().length) {
      _cachedSublevels = _getSortedSublevels(sublevels.toList());
    }

    if (loadingLevelIds.isNotEmpty && _cachedSublevels!.isEmpty) {
      return const Loader();
    }

    return Scaffold(
      appBar: const HomeScreenAppBar(),
      body: SublevelsList(
        loadingIds: loadingLevelIds,
        sublevels: _cachedSublevels!,
        onVideoChange: onVideoChange,
      ),
    );
  }
}
