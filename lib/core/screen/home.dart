import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/constants.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref
          .read(sublevelControllerProvider.notifier)
          .handleFetchSublevels();
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
    int? doneToday,
  ) {
    if (isAdmin) return false;

    final levelAfter =
        !hasLocalProgress ||
        isLevelAfter(level, subLevel, maxLevel, maxSubLevel);

    if (!levelAfter) return false;

    if (isDailyLimitReached(doneToday)) return true;

    final hasFinishedVideo =
        ref.read(sublevelControllerProvider).hasFinishedVideo;

    if (hasFinishedVideo) return false;

    showSnackBar(
      context,
      'Please complete the current sublevel before proceeding',
    );

    return true;
  }

  bool isDailyLimitReached(int? doneToday) {
    final done = doneToday ?? SharedPref.get(PrefKey.doneToday);

    final exceedsDailyLimit =
        done != null && done >= kMaxLevelCompletionsPerDay;

    if (doneToday == null) {
      if (exceedsDailyLimit) {
        showSnackBar(
          context,
          'Connection failed please click on reload icon at the top right corner',
        );

        return true;
      }
    } else {
      if (exceedsDailyLimit) {
        showSnackBar(
          context,
          'You can only complete $kMaxLevelCompletionsPerDay levels per day',
        );
        return true;
      }
    }

    return false;
  }

  Future<bool> handleFetchSublevels(int index) async {
    if (isLevelChanged(index, _cachedSublevels!)) {
      await fetchSublevels();
    }

    if (index < _cachedSublevels!.length) return false;

    await ref.read(sublevelControllerProvider.notifier).handleFetchSublevels();

    return true;
  }

  Future<void> syncProgress(
    int index,
    List<SubLevel> sublevels,
    String? userEmail,
    int subLevel,
    int maxLevel,
  ) async {
    if (isLevelChanged(index, sublevels)) return;

    bool isSyncSucceed = false;

    if (userEmail != null) {
      final currSubLevel = sublevels[index];
      isSyncSucceed = await ref
          .read(userControllerProvider.notifier)
          .sync(currSubLevel.levelId, subLevel);
    }

    await updateDailyProgressIfNeeded(
      sublevels,
      index,
      maxLevel,
      isSyncSucceed,
    );
  }

  bool isLevelChanged(int index, List<SubLevel> sublevels) {
    if (index <= 0) return true;

    final previousSubLevel = sublevels[index - 1];
    final currSubLevel = sublevels[index];

    return previousSubLevel.levelId == currSubLevel.levelId;
  }

  Future<void> fetchSublevels() async {
    await ref.read(sublevelControllerProvider.notifier).handleFetchSublevels();
  }

  Future<void> updateDailyProgressIfNeeded(
    List<SubLevel> sublevels,
    int index,
    int maxLevel,
    bool isSyncSucceed,
  ) async {
    final previousSubLevel = sublevels[index - 1];
    final currSubLevel = sublevels[index];

    if (((previousSubLevel.level < currSubLevel.level &&
                previousSubLevel.level <= maxLevel) ||
            !isSyncSucceed) &&
        currSubLevel.level > kAuthRequiredLevel) {
      await SharedPref.store(PrefKey.doneToday, 1);
    }
  }

  Future<void> syncActivityLogs() async {
    // Check if enough time has passed since the last sync
    final lastSync = SharedPref.get(PrefKey.lastSync) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastSync;

    if (diff < kMinProgressSyncingDiffInMillis) return;

    // If the user is logged in, sync their progress with the server
    // Sync any pending activity logs with the server
    final activityLogs = SharedPref.get(PrefKey.activityLogs);

    if (activityLogs == null || activityLogs.isEmpty) return;

    await ref
        .read(activityLogControllerProvider.notifier)
        .syncActivityLogs(activityLogs);

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
    String? userEmail,
  ) async {
    final isCurrLevelAfter = isLevelAfter(
      level,
      sublevelIndex,
      localMaxLevel,
      localMaxSubLevel,
    );

    // Update the user's current progress in shared preferences
    await SharedPref.copyWith(
      PrefKey.currProgress(userEmail: userEmail),
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

    final userEmail = user?.email;

    final localProgress = SharedPref.get(
      PrefKey.currProgress(userEmail: userEmail),
    );

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
      user?.doneToday,
    )) {
      controller.animateToPage(
        index - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(false);

    // Sync the local progress
    await syncLocalProgress(
      level,
      sublevelIndex,
      sublevel.levelId,
      localMaxLevel,
      localMaxSubLevel,
      userEmail,
    );

    final lastLoggedInEmail = SharedPref.get(PrefKey.lastLoggedInEmail);

    // If the level requires auth and the user is not logged in, redirect to sign in
    if (level > kAuthRequiredLevel && lastLoggedInEmail == null && mounted) {
      context.go(Routes.signIn);
      return;
    }

    if (lastLoggedInEmail == null) return;

    // If the user is logged in, add an activity log entry
    await SharedPref.pushValue(
      PrefKey.activityLogs,
      ActivityLog(
        subLevel: sublevelIndex,
        level: level,
        userEmail: userEmail ?? lastLoggedInEmail,
      ),
    );

    // Sync the progress with db if the user moves to a new level
    await syncProgress(
      index,
      _cachedSublevels!,
      userEmail,
      sublevelIndex,
      user?.maxLevel ?? 0,
    );

    // Sync the last sync time with the server
    await syncActivityLogs();
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
    final loadingLevelIds = ref.watch(
      sublevelControllerProvider.select((state) => state.loadingLevelIds),
    );

    final sublevels = ref.watch(
      sublevelControllerProvider.select((state) => state.sublevels),
    );

    // Only sort sublevels if they have changed
    if (_cachedSublevels == null ||
        _cachedSublevels!.length != sublevels.toList().length) {
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
