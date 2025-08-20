import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/activityLog/activity_log.controller.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/views/widgets/home_app_bar.dart';
import 'package:myapp/views/widgets/home_app_bar_animated.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/sublevel_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(levelControllerProvider.notifier).fetchLevels();
    });
  }

  bool cancelVideoChange(
    int maxLevel,
    int maxSubLevel,
    int level,
    int subLevel,
    bool hasLocalProgress,
    bool isAdmin,
    int? doneToday,
  ) {
    if (isAdmin) return false;

    final levelAfter = !hasLocalProgress || isLevelAfter(level, subLevel, maxLevel, maxSubLevel);
    if (!levelAfter) return false;

    if (isDailyLimitReached(doneToday)) return true;

    final hasFinishedVideo = ref.read(sublevelControllerProvider).hasFinishedSublevel;
    if (hasFinishedVideo) return false;

    showSnackBar(
      context,
      message: choose(
        hindi: 'कृपया आगे बढ़ने से पहले वर्तमान वीडियो पूरा करें',
        hinglish: 'Kripya aage badne se pehle current video ko complete karein',
        lang: ref.read(langControllerProvider),
      ),
      type: SnackBarType.error,
    );

    return true;
  }

  bool isDailyLimitReached(int? doneToday) {
    final isDoneTodayNull = doneToday == null || doneToday == 0;

    final done = isDoneTodayNull ? SharedPref.get(PrefKey.doneToday) : doneToday;

    final exceedsDailyLimit = done != null && done >= AppConstants.kMaxLevelCompletionsPerDay;

    if (!exceedsDailyLimit) return false;

    showSnackBar(
      context,
      message: choose(
        hinglish:
            isDoneTodayNull
                ? 'Connection fail ho gaya hai, kripya upar right corner mein diye gaye reload icon par click karein.'
                : 'Aap har din sirf ${AppConstants.kMaxLevelCompletionsPerDay} levels complete kar sakte hain.',
        hindi:
            isDoneTodayNull
                ? 'कनेक्शन नहीं हो पाया, ऊपर दाएँ कोने में रीलोड वाले आइकन पर क्लिक करें।'
                : 'आप हर दिन सिर्फ ${AppConstants.kMaxLevelCompletionsPerDay} लेवल पूरा कर सकते हैं।',
        lang: ref.read(langControllerProvider),
      ),
      type: SnackBarType.error,
    );

    return true;
  }

  Future<void> handleFetchSublevels(int index, List<SubLevel> sublevels) async {
    if (isLevelChanged(index, sublevels)) {
      final newLevelId = sublevels[index].levelId;
      await fetchSublevels(anchorLevelId: newLevelId);
    }
  }

  Future<void> syncProgress(int index, List<SubLevel> sublevels, String? userEmail, int subLevel, int maxLevel) async {
    if (!isLevelChanged(index, sublevels)) return;

    bool isSyncSucceed = false;

    if (userEmail != null) {
      final currSubLevel = sublevels[index];
      isSyncSucceed = await ref.read(userControllerProvider.notifier).sync(currSubLevel.levelId, subLevel);
    }

    final previousSubLevel = sublevels[index - 1];
    final currSubLevel = sublevels[index];

    if (((previousSubLevel.level < currSubLevel.level) || !isSyncSucceed) && currSubLevel.level > maxLevel) {
      final doneToday = SharedPref.get(PrefKey.doneToday);

      await SharedPref.store(PrefKey.doneToday, doneToday! + 1);
    }
  }

  bool isLevelChanged(int index, List<SubLevel> sublevels) {
    if (index <= 0 || index >= sublevels.length) return false;

    final previousSubLevel = sublevels[index - 1];
    final currSubLevel = sublevels[index];

    return previousSubLevel.levelId != currSubLevel.levelId;
  }

  Future<void> fetchSublevels({String? anchorLevelId}) async {
    await ref.read(levelControllerProvider.notifier).fetchLevels();
  }

  Future<void> syncActivityLogs() async {
    final lastSync = SharedPref.get(PrefKey.lastSync) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastSync;
    if (diff < AppConstants.kMinProgressSyncingDiffInMillis) return;

    final activityLogs = SharedPref.get(PrefKey.activityLogs);

    if (activityLogs == null || activityLogs.isEmpty) return;

    await ref.read(activityLogControllerProvider.notifier).syncActivityLogs(activityLogs);

    await SharedPref.removeValue(PrefKey.activityLogs);

    await SharedPref.store(PrefKey.lastSync, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> syncLocalProgress(
    int level,
    int sublevelIndex,
    String levelId,
    int localMaxLevel,
    int localMaxSubLevel,
    String? userEmail,
  ) async {
    final isCurrLevelAfter = isLevelAfter(level, sublevelIndex, localMaxLevel, localMaxSubLevel);

    // Update the user's current progress using UI controller
    final progress = Progress(
      level: level,
      subLevel: sublevelIndex,
      levelId: levelId,
      maxLevel: isCurrLevelAfter ? level : localMaxLevel,
      maxSubLevel: isCurrLevelAfter ? sublevelIndex : localMaxSubLevel,
    );

    await ref.read(uIControllerProvider.notifier).storeProgress(progress, userEmail: userEmail);
  }

  Future<void> onSublevelChange(int index, PageController controller) async {
    if (!mounted) {
      return;
    }

    final sublevels = ref.read(sublevelControllerProvider).sublevels?.toList();
    if (sublevels == null || sublevels.isEmpty || index < 0 || index >= sublevels.length) {
      return;
    }

    final sublevel = sublevels[index];
    final level = sublevel.level;
    final sublevelIndex = sublevel.index;

    final user = ref.read(userControllerProvider.notifier).getUser();

    final userEmail = user?.email;

    final localProgress = ref.read(uIControllerProvider).currentProgress;

    final localMaxLevel = localProgress?.maxLevel ?? 0;
    final localMaxSubLevel = localProgress?.maxSubLevel ?? 0;

    final isLocalLevelAfter = isLevelAfter(level, sublevelIndex, user?.maxLevel ?? 0, user?.maxSubLevel ?? 0);

    if (cancelVideoChange(
      isLocalLevelAfter ? localMaxLevel : user?.maxLevel ?? 0,
      isLocalLevelAfter ? localMaxSubLevel : user?.maxSubLevel ?? 0,
      level,
      sublevelIndex,
      localProgress != null,
      user?.isAdmin == true,
      user?.doneToday,
    )) {
      final currentBufferPage = ((controller.page ?? controller.initialPage).round());
      final targetPage = currentBufferPage > controller.initialPage ? currentBufferPage - 1 : controller.initialPage;
      await controller.animateToPage(targetPage, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(false);

    final prevProgress = ref.read(uIControllerProvider).currentProgress;
    await syncLocalProgress(level, sublevelIndex, sublevel.levelId, localMaxLevel, localMaxSubLevel, userEmail);

    // Trigger level prefetch immediately when the level changes (works for both directions, e.g., 4-1 -> 3-5)
    if (prevProgress?.levelId != sublevel.levelId) {
      await ref.read(levelControllerProvider.notifier).fetchLevels();
    }

    // Also run existing handler (kept for forward boundary scenarios)
    await handleFetchSublevels(index, sublevels);

    final lastLoggedInEmail = SharedPref.get(PrefKey.user)?.email;

    if (lastLoggedInEmail == null) {
      return;
    }
    await SharedPref.pushValue(
      PrefKey.activityLogs,
      ActivityLog(subLevel: sublevelIndex, levelId: sublevel.levelId, userEmail: userEmail ?? lastLoggedInEmail),
    );

    await syncProgress(index, sublevels, userEmail, sublevelIndex, user?.maxLevel ?? 0);

    await syncActivityLogs();
  }

  // Removed sorting; sublevels are now passed as-is to SublevelsList

  @override
  Widget build(BuildContext context) {
    final loadingLevelIds = ref.watch(levelControllerProvider.select((state) => state.loadingById));
    final sublevels = ref.watch(sublevelControllerProvider.select((state) => state.sublevels));
    final orientation = MediaQuery.of(context).orientation;

    if (sublevels == null || sublevels.isEmpty) {
      return const Loader();
    }

    if (loadingLevelIds.values.any((value) => value) && sublevels.isEmpty) {
      return const Loader();
    }

    return Scaffold(
      body:
          orientation == Orientation.landscape
              ? // Landscape: Static app bar takes actual space
              Column(
                children: [
                  const HomeAppBar(),
                  Expanded(
                    child: SublevelsList(
                      loadingById: loadingLevelIds,
                      sublevels: sublevels.toList(),
                      onSublevelChange: onSublevelChange,
                    ),
                  ),
                ],
              )
              : // Portrait: Animated app bar over content
              Stack(
                children: [
                  SublevelsList(
                    loadingById: loadingLevelIds,
                    sublevels: sublevels.toList(),
                    onSublevelChange: onSublevelChange,
                  ),
                  const HomeAppBarAnimated(),
                ],
              ),
    );
  }
}
