import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/scroll_indicator.dart';
import 'package:myapp/views/widgets/sublevel_video_player/sublevel_video_player.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/views/screens/error_page.dart';
import 'package:myapp/views/screens/speech_exercise_screen.dart';
import 'package:myapp/controllers/user/user_controller.dart';
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

class _SublevelsListState extends ConsumerState<SublevelsList> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _showAnimation = false;
  Timer? _animationTimer;

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
    _showAnimation = true;
    _animationTimer?.cancel();
    _animationTimer = Timer(const Duration(milliseconds: 3750), () {
      if (mounted) {
        setState(() {
          _showAnimation = false;
        });
        _bounceController.dispose();
        _animationTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bounceController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 30.0,
    ).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));

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
    _bounceController.dispose();
    _animationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sublevelControllerProvider.select((value) => value.hasFinishedVideo), (previous, next) {
      if (next) {
        _startAnimationTimer();
        _bounceController.repeat(reverse: true);
      } else {
        _bounceController.stop();
        _bounceController.reset();
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
          _bounceController.stop();
          _bounceController.reset();
          setState(() {
            _showAnimation = false;
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

            Console.error(APIError(message: 'sublevel error is $error $index'), StackTrace.current);

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

          final positionText = '${sublevel.level}-${sublevel.index}';

          return AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _showAnimation ? -_bounceAnimation.value : 0),
                child: Stack(
                  children: [
                    Center(
                      child: sublevel.when(
                        video: (video) => SublevelVideoPlayer(key: Key(positionText), subLevel: sublevel),
                        speechExercise:
                            (speechExercise) => SpeechExerciseScreen(
                              key: Key(positionText),
                              exercise: speechExercise,
                              goToNext: () {
                                _pageController.animateToPage(
                                  index + 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                      ),
                    ),

                    if (_showAnimation)
                      const Positioned(bottom: 40, left: 0, right: 0, child: Center(child: ScrollIndicator())),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
