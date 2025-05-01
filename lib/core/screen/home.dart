import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
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
import 'package:myapp/core/controllers/interstitial_ad_controller.dart';
import 'package:myapp/core/widgets/interstitial_ad_handler.dart';
import 'dart:async';
import 'package:myapp/core/services/analytics_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<SubLevel>? _sortedSublevels;
  int _videosWatched = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(sublevelControllerProvider.notifier).fetchSublevels();
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
    String levelId,
  ) {
    if (isAdmin) return false;

    final levelAfter = !hasLocalProgress || isLevelAfter(level, subLevel, maxLevel, maxSubLevel);

    if (!levelAfter) return false;

    if (isDailyLimitReached(doneToday)) return true;

    final hasFinishedVideo = ref.read(sublevelControllerProvider).hasFinishedVideo;

    if (hasFinishedVideo) return false;

    showSnackBar(
      context,
      message: ref
          .read(langProvider.notifier)
          .prefLangText(
            const PrefLangText(
              hindi: 'कृपया आगे बढ़ने से पहले वर्तमान वीडियो पूरा करें',
              hinglish: 'Kripya aage badne se pehle current video ko complete karein',
            ),
          ),
      type: SnackBarType.error,
    );

    unawaited(AnalyticsService().attemptScrollForward(level: level, sublevel: subLevel, levelId: levelId));

    return true;
  }

  bool isDailyLimitReached(int? doneToday) {
    final isDoneTodayNull = doneToday == null || doneToday == 0;

    final done = isDoneTodayNull ? SharedPref.get(PrefKey.doneToday) : doneToday;

    final exceedsDailyLimit = done != null && done >= AppConstants.kMaxLevelCompletionsPerDay;

    if (!exceedsDailyLimit) return false;

    showSnackBar(
      context,
      message: ref
          .read(langProvider.notifier)
          .prefLangText(
            PrefLangText(
              hinglish:
                  isDoneTodayNull
                      ? 'Connection fail ho gaya hai, kripya upar right corner mein diye gaye reload icon par click karein.'
                      : 'Aap har din sirf ${AppConstants.kMaxLevelCompletionsPerDay} levels complete kar sakte hain.',
              hindi:
                  isDoneTodayNull
                      ? 'कनेक्शन नहीं हो पाया, ऊपर दाएँ कोने में रीलोड वाले आइकन पर क्लिक करें।'
                      : 'आप हर दिन सिर्फ ${AppConstants.kMaxLevelCompletionsPerDay} लेवल पूरा कर सकते हैं।',
            ),
          ),
      type: SnackBarType.error,
    );

    return true;
  }

  Future<bool> handleFetchSublevels(int index) async {
    if (isLevelChanged(index, _sortedSublevels!)) {
      await fetchSublevels();
    }

    if (index < _sortedSublevels!.length) return false;

    await ref.read(sublevelControllerProvider.notifier).fetchSublevels();

    return true;
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

  Future<void> fetchSublevels() async {
    await ref.read(sublevelControllerProvider.notifier).fetchSublevels();
  }

  Future<void> syncActivityLogs() async {
    // Check if enough time has passed since the last sync
    final lastSync = SharedPref.get(PrefKey.lastSync) ?? 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - lastSync;
    if (diff < AppConstants.kMinProgressSyncingDiffInMillis) return;

    // If the user is logged in, sync their progress with the server
    // Sync any pending activity logs with the server
    final activityLogs = SharedPref.get(PrefKey.activityLogs);

    if (activityLogs == null || activityLogs.isEmpty) return;

    await ref.read(activityLogControllerProvider.notifier).syncActivityLogs(activityLogs);

    // Clear the activity logs and update the last sync time
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
    if (!mounted || _sortedSublevels == null) return;

    // If the index is greater than the length of the cached sublevels, fetch the sublevels and return
    if (await handleFetchSublevels(index)) return;

    // Get the sublevel, level, and sublevel for the current index
    final sublevel = _sortedSublevels![index];
    final level = sublevel.level;
    final sublevelIndex = sublevel.index;

    // Get the user's email
    final user = ref.read(userControllerProvider).currentUser;

    final userEmail = user?.email;

    final localProgress = SharedPref.get(PrefKey.currProgress(userEmail: userEmail));

    final localMaxLevel = localProgress?.maxLevel ?? 0;
    final localMaxSubLevel = localProgress?.maxSubLevel ?? 0;

    final isLocalLevelAfter = isLevelAfter(level, sublevelIndex, user?.maxLevel ?? 0, user?.maxSubLevel ?? 0);

    // Capture Backward Scroll analytics
    final previousSublevel = localProgress?.subLevel ?? 0;
    final previousLevel = localProgress?.level ?? 0;
    final previousLevelId = localProgress?.levelId ?? '';

    final isScrolledBackwards = isLevelAfter(previousLevel, previousSublevel, level, sublevelIndex);

    if (isScrolledBackwards) {
      unawaited(
        AnalyticsService().scrollBackward(
          fromLevel: previousLevel,
          fromSublevel: previousSublevel,
          toLevel: level,
          toSublevel: sublevelIndex,
          fromLevelId: previousLevelId,
          toLevelId: sublevel.levelId,
        ),
      );
    }
    //--------------------------------

    // Check if video change should be cancelled
    if (cancelVideoChange(
      isLocalLevelAfter ? localMaxLevel : user?.maxLevel ?? 0,
      isLocalLevelAfter ? localMaxSubLevel : user?.maxSubLevel ?? 0,
      level,
      sublevelIndex,
      localProgress != null,
      user?.isAdmin == true,
      user?.doneToday,
      sublevel.levelId,
    )) {
      controller.animateToPage(index - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(false);

    // Sync the local progress
    await syncLocalProgress(level, sublevelIndex, sublevel.levelId, localMaxLevel, localMaxSubLevel, userEmail);

    final lastLoggedInEmail = SharedPref.get(PrefKey.user)?.email;

    if (lastLoggedInEmail == null) return;

    // If the user is logged in, add an activity log entry
    await SharedPref.pushValue(
      PrefKey.activityLogs,
      ActivityLog(subLevel: sublevelIndex, levelId: sublevel.levelId, userEmail: userEmail ?? lastLoggedInEmail),
    );

    // Sync the progress with db if the user moves to a new level
    await syncProgress(index, _sortedSublevels!, userEmail, sublevelIndex, user?.maxLevel ?? 0);

    // Sync the last sync time with the server
    await syncActivityLogs();

    _videosWatched++;

    if (_videosWatched > AppConstants.adSubLevelCount) {
      ref.read(interstitialAdNotifierProvider.notifier).setShowAd(true);
      return;
    }
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
    final loadingLevelIds = ref.watch(sublevelControllerProvider.select((state) => state.loadingLevelIds));

    final sublevels = ref.watch(sublevelControllerProvider.select((state) => state.sublevels));

    final showAd = ref.watch(interstitialAdNotifierProvider.select((state) => state.showAd));

    if (showAd) {
      return InterstitialAdHandler(
        onAdFinished: () {
          _videosWatched = 0;
        },
      );
    }

    if (sublevels == null) {
      return const Loader();
    }

    // Only sort sublevels if they have changed
    if (_sortedSublevels == null || _sortedSublevels!.length != sublevels.toList().length) {
      _sortedSublevels = _getSortedSublevels(sublevels.toList());
    }

    if (loadingLevelIds.isNotEmpty && _sortedSublevels!.isEmpty) {
      return const Loader();
    }

    return Scaffold(
      // appBar: const HomeScreenAppBar(),
      body: SublevelsList(loadingIds: loadingLevelIds, sublevels: _sortedSublevels!, onVideoChange: onVideoChange),
    );
  }
}
