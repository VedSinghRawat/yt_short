import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/scroll_indicator.dart';
import 'package:myapp/views/widgets/video_player/video_player_screen.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/views/screens/error_screen.dart';
import 'package:myapp/views/screens/speech_exercise_screen.dart';
import 'package:myapp/views/screens/arrange_exercise_screen.dart';
import 'package:myapp/views/screens/fill_exercise_screen.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'dart:async';

class SublevelsList extends ConsumerStatefulWidget {
  final List<SubLevel> sublevels;
  final Map<String, bool> loadingById;
  final Future<void> Function(int index, PageController controller)? onSublevelChange;

  const SublevelsList({super.key, required this.sublevels, this.onSublevelChange, required this.loadingById});

  @override
  ConsumerState<SublevelsList> createState() => _SublevelsListState();
}

class _SublevelsListState extends ConsumerState<SublevelsList> {
  late PageController _pageController;
  bool _showAnimation = false;
  bool _showScrollIndicator = false;
  Timer? _animationTimer;
  Timer? _bounceTimer;
  int _currentPageIndex = 0;

  Future<void> _jumpToPage() async {
    final userEmail = ref.read(userControllerProvider.notifier).getUser()?.email;

    final progress = ref.read(uIControllerProvider).currentProgress;

    final jumpTo = widget.sublevels.indexWhere(
      (sublevel) => (sublevel.index == progress?.subLevel && sublevel.level == progress?.level),
    );

    if (jumpTo >= widget.sublevels.length || jumpTo < 0) return;

    if (_pageController.page?.round() == jumpTo) return;

    final jumpSublevel = widget.sublevels[jumpTo];

    _pageController.jumpToPage(jumpTo);

    // Set initial app bar visibility based on sublevel type
    jumpSublevel.when(
      video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
      speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
      arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
      fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
    );

    final progressUpdate = Progress(level: jumpSublevel.level, subLevel: jumpSublevel.index);
    await ref.read(uIControllerProvider.notifier).storeProgress(progressUpdate, userEmail: userEmail);
  }

  void _startAnimationTimer() {
    _animationTimer?.cancel();
    _bounceTimer?.cancel();

    setState(() {
      _showScrollIndicator = true;
    });

    // Create bouncing effect by toggling animation state multiple times
    int bounceCount = 0;
    const maxBounces = 6; // 3 complete bounces (up-down cycles)

    _bounceTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _showAnimation = !_showAnimation;
      });

      bounceCount++;
      if (bounceCount >= maxBounces) {
        timer.cancel();
        // Ensure animation ends in the normal position
        if (mounted) {
          setState(() {
            _showAnimation = false;
            _showScrollIndicator = false;
          });
        }
      }
    });

    // Store the timer reference for cleanup
    _animationTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() {
          _showAnimation = false;
          _showScrollIndicator = false;
        });
        _animationTimer?.cancel();
      }
    });
  }

  void _goNextSublevel(int index) {
    ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
    _pageController.animateToPage(index + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  bool _isLoadingRelevantLevels(WidgetRef ref) {
    // If we have no sublevels, any loading is relevant
    if (widget.sublevels.isEmpty) return widget.loadingById.isNotEmpty;

    final levelState = ref.read(levelControllerProvider);
    final orderedIds = levelState.orderedIds;

    // If we don't have orderedIds, fall back to checking any loading
    if (orderedIds == null) return widget.loadingById.isNotEmpty;

    final lastLoadedLevelId = widget.sublevels.last.levelId;
    final lastLoadedIndex = orderedIds.indexOf(lastLoadedLevelId);

    // If we can't find the last loaded level in orderedIds, fall back to checking any loading
    if (lastLoadedIndex == -1) return widget.loadingById.isNotEmpty;

    // Check if we're loading any levels after the last loaded level
    for (int i = lastLoadedIndex + 1; i < orderedIds.length; i++) {
      final levelId = orderedIds[i];
      if (widget.loadingById[levelId] == true) {
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToPage());
  }

  @override
  void didUpdateWidget(covariant SublevelsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sublevels.length == widget.sublevels.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToPage());
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _bounceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userControllerProvider.select((value) => value.currentUser), (previous, next) {
      if (next == null) return;
      //  if profile is reset, jump to first sublevel
      final progress = ref.read(uIControllerProvider).currentProgress;
      final currentIndex = _pageController.page?.round() ?? 0;

      if (progress?.level == 1 &&
          progress?.subLevel == 1 &&
          !(widget.sublevels[currentIndex].level == 1 && widget.sublevels[currentIndex].index == 0)) {
        _jumpToPage();
      }
    });

    ref.listen(sublevelControllerProvider.select((value) => value.hasFinishedSublevel), (previous, next) {
      final progress = ref.read(uIControllerProvider).currentProgress;

      if (!isLevelEqual(
            progress?.level ?? 0,
            progress?.subLevel ?? 0,
            progress?.maxLevel ?? 0,
            progress?.maxSubLevel ?? 0,
          ) ||
          !next) {
        return;
      }

      // Only show animation if the current sublevel is a video
      final currentIndex = _pageController.page?.round() ?? 0;
      if (currentIndex < widget.sublevels.length) {
        final currentSublevel = widget.sublevels[currentIndex];
        currentSublevel.when(
          video: (video) => _startAnimationTimer(), // Only start animation for video
          speechExercise: (speechExercise) => {}, // No animation for speech exercise
          arrangeExercise: (arrangeExercise) => {}, // No animation for arrange exercise
          fillExercise: (fillExercise) => {}, // No animation for fill exercise
        );
      }
    });

    ref.listen(uIControllerProvider.select((value) => value.isAppBarVisible), (previous, isVisible) {
      if (isVisible) {
        _animationTimer?.cancel();
        _bounceTimer?.cancel();
        if (mounted) {
          setState(() {
            _showAnimation = false;
            _showScrollIndicator = false;
          });
        }
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.sublevels[0].level == 1 && widget.sublevels[0].index == 0) return;

        await Future.delayed(const Duration(seconds: 5));
      },
      child: PageView.builder(
        controller: _pageController,
        allowImplicitScrolling: true,
        dragStartBehavior: DragStartBehavior.down,
        itemCount: widget.sublevels.length + 1,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) async {
          _animationTimer?.cancel();
          _bounceTimer?.cancel();
          setState(() {
            _showAnimation = false;
            _showScrollIndicator = false;
            _currentPageIndex = index;
          });

          // Control app bar visibility based on sublevel type
          if (index < widget.sublevels.length) {
            final sublevel = widget.sublevels[index];
            sublevel.when(
              video: (video) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(false),
              speechExercise: (speechExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
              arrangeExercise: (arrangeExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
              fillExercise: (fillExercise) => ref.read(uIControllerProvider.notifier).setIsAppBarVisible(true),
            );
          }

          await widget.onSublevelChange?.call(index, _pageController);
        },
        itemBuilder: (context, index) {
          final sublevel = widget.sublevels.length > index ? widget.sublevels[index] : null;

          final isLoading =
              sublevel == null ? _isLoadingRelevantLevels(ref) : (widget.loadingById[sublevel.levelId] ?? true);

          if (sublevel == null && !isLoading) {
            final levelState = ref.read(levelControllerProvider);
            final orderedIds = levelState.orderedIds;
            final lastAvailableLevelId = orderedIds?.last;

            final lastLoadedLevelId = widget.sublevels.isNotEmpty ? widget.sublevels.last.levelId : null;

            final isAtLastAvailableLevel =
                lastAvailableLevelId != null && lastLoadedLevelId != null && lastLoadedLevelId == lastAvailableLevelId;

            if (isAtLastAvailableLevel) {
              return ErrorPage(
                onButtonClick: () async {
                  // Show loading feedback
                  showSnackBar(
                    context,
                    message: choose(
                      hindi: 'नए लेवल्स चेक कर रहे हैं...',
                      hinglish: 'Naye levels check kar rahe hain...',
                      lang: ref.read(langControllerProvider),
                    ),
                    type: SnackBarType.info,
                  );

                  try {
                    final levelController = ref.read(levelControllerProvider.notifier);
                    final currentOrderedIds = ref.read(levelControllerProvider).orderedIds?.length ?? 0;

                    await levelController.getOrderedIds();
                    await levelController.fetchLevels();

                    final newOrderedIds = ref.read(levelControllerProvider).orderedIds?.length ?? 0;

                    if (newOrderedIds > currentOrderedIds) {
                      showSnackBar(
                        context,
                        message: choose(
                          hindi: 'नए लेवल्स मिल गए! 🎉',
                          hinglish: 'Naye levels mil gaye! 🎉',
                          lang: ref.read(langControllerProvider),
                        ),
                        type: SnackBarType.success,
                      );
                    } else {
                      showSnackBar(
                        context,
                        message: choose(
                          hindi: 'अभी कोई नए लेवल्स नहीं हैं',
                          hinglish: 'Abhi koi naye levels nahi hain',
                          lang: ref.read(langControllerProvider),
                        ),
                        type: SnackBarType.info,
                      );
                    }

                    await widget.onSublevelChange?.call(index, _pageController);
                  } catch (e) {
                    showSnackBar(
                      context,
                      message: choose(
                        hindi: 'कुछ गलत हुआ। कृपया बाद में कोशिश करें।',
                        hinglish: 'Kuch galat hua. Kripya baad mein koshish karein.',
                        lang: ref.read(langControllerProvider),
                      ),
                      type: SnackBarType.error,
                    );
                  }
                },
                text: choose(
                  hindi: 'अभी इतने ही लेवल्स हैं। कुछ समय बाद नीचे दिए गए बटन पर क्लिक करके चेक करें।',
                  hinglish:
                      'Abhi itne he levels hai. Kuch time baad niche diye gye button par click karke check karein.',
                  lang: ref.read(langControllerProvider),
                ),
                buttonText: choose(
                  hindi: 'अगला लेवल लोड करें',
                  hinglish: 'Agla level load karein',
                  lang: ref.read(langControllerProvider),
                ),
              );
            }

            final error = ref.watch(sublevelControllerProvider).error;

            if (error == null) {
              return const Loader();
            }

            return ErrorPage(
              onButtonClick: () => widget.onSublevelChange?.call(index, _pageController),
              text: error,
              buttonText: choose(hindi: 'पुनः प्रयास करें', hinglish: 'Retry', lang: ref.read(langControllerProvider)),
            );
          }

          if (sublevel == null) {
            return const Loader();
          }

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                top: _showAnimation ? -30 : 0,
                left: 0,
                right: 0,
                bottom: _showAnimation ? 30 : 0,
                child: Stack(
                  children: [
                    Center(
                      child: sublevel.when(
                        video: (video) => VideoPlayerScreen(video: video),
                        speechExercise:
                            (speechExercise) => SpeechExerciseScreen(
                              exercise: speechExercise,
                              goToNext: () => _goNextSublevel(index),
                              isVisible: _currentPageIndex == index,
                            ),
                        arrangeExercise:
                            (arrangeExercise) => ArrangeExerciseScreen(
                              exercise: arrangeExercise,
                              goToNext: () => _goNextSublevel(index),
                              isVisible: _currentPageIndex == index,
                            ),
                        fillExercise:
                            (fillExercise) => FillExerciseScreen(
                              exercise: fillExercise,
                              goToNext: () => _goNextSublevel(index),
                              isCurrent: _currentPageIndex == index,
                            ),
                      ),
                    ),

                    if (_showScrollIndicator)
                      const Positioned(bottom: 40, left: 0, right: 0, child: Center(child: ScrollIndicator())),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
