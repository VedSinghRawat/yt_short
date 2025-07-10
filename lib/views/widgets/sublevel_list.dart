import 'package:flutter/gestures.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/scroll_indicator.dart';
import 'package:myapp/views/widgets/video_player/video_player_screen.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/views/screens/error_page.dart';
import 'package:myapp/views/screens/speech_exercise_screen.dart';
import 'package:myapp/views/screens/arrange_exercise_screen.dart';
import 'package:myapp/views/screens/fill_exercise_screen.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'dart:async';

class SublevelsList extends ConsumerStatefulWidget {
  final List<SubLevel> sublevels;
  final Map<String, bool> loadingIds;
  final Future<void> Function(int index, PageController controller)? onVideoChange;

  const SublevelsList({super.key, required this.sublevels, this.onVideoChange, required this.loadingIds});

  @override
  ConsumerState<SublevelsList> createState() => _SublevelsListState();
}

class _SublevelsListState extends ConsumerState<SublevelsList> {
  late PageController _pageController;
  bool _showAnimation = false;
  bool _showScrollIndicator = false;
  Timer? _animationTimer;
  Timer? _bounceTimer;

  void _jumpToPage(Duration timeStamp) async {
    final userEmail = ref.read(userControllerProvider).currentUser?.email;

    final progress = SharedPref.get(PrefKey.currProgress(userEmail: userEmail));

    final jumpTo = widget.sublevels.indexWhere(
      (sublevel) => (sublevel.index == progress?.subLevel && sublevel.level == progress?.level),
    );

    if (jumpTo >= widget.sublevels.length || jumpTo < 0) return;

    if (_pageController.page?.round() == jumpTo) return;

    final jumpSublevel = widget.sublevels[jumpTo];

    _pageController.jumpToPage(jumpTo);

    await SharedPref.copyWith(
      PrefKey.currProgress(userEmail: userEmail),
      Progress(level: jumpSublevel.level, subLevel: jumpSublevel.index),
    );
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback(_jumpToPage);
  }

  @override
  void didUpdateWidget(covariant SublevelsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sublevels.length == widget.sublevels.length) return;

    WidgetsBinding.instance.addPostFrameCallback(_jumpToPage);
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
      final progress = SharedPref.get(PrefKey.currProgress());
      final currentIndex = _pageController.page?.round() ?? 0;

      if (progress?.level == 1 &&
          progress?.subLevel == 1 &&
          !(widget.sublevels[currentIndex].level == 1 && widget.sublevels[currentIndex].index == 0)) {
        _jumpToPage(Duration.zero);
      }
    });

    ref.listen(sublevelControllerProvider.select((value) => value.hasFinishedSublevel), (previous, next) {
      final progress = SharedPref.get(PrefKey.currProgress());

      if (!isLevelEqual(
        progress?.level ?? 0,
        progress?.subLevel ?? 0,
        progress?.maxLevel ?? 0,
        progress?.maxSubLevel ?? 0,
      )) {
        return;
      }

      if (next) {
        _startAnimationTimer();
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
          });
          await widget.onVideoChange?.call(index, _pageController);
        },
        itemBuilder: (context, index) {
          final sublevel = widget.sublevels.length > index ? widget.sublevels[index] : null;

          final isLastSublevel = index == widget.sublevels.length;

          final isLoading =
              sublevel == null ? widget.loadingIds.isNotEmpty : (widget.loadingIds[sublevel.levelId] ?? true);

          if ((isLastSublevel || sublevel == null) && !isLoading) {
            final error = ref.watch(sublevelControllerProvider).error;

            developer.log('sublevel error is $error $index', name: 'SublevelsList');

            if (error == null) {
              return const Loader();
            }

            return ErrorPage(
              onRefresh: () => widget.onVideoChange?.call(index, _pageController),
              text: error,
              buttonText: ref
                  .read(langControllerProvider.notifier)
                  .choose(hindi: 'पुनः प्रयास करें', hinglish: 'Retry'),
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
                              goToNext: () {
                                ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
                                _pageController.animateToPage(
                                  index + 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                        arrangeExercise:
                            (arrangeExercise) => ArrangeExerciseScreen(
                              exercise: arrangeExercise,
                              goToNext: () {
                                ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
                                _pageController.animateToPage(
                                  index + 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                        fillExercise:
                            (fillExercise) => FillExerciseScreen(
                              exercise: fillExercise,
                              goToNext: () {
                                ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
                                _pageController.animateToPage(
                                  index + 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
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
