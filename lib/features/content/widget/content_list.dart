import 'package:flutter/material.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/yt_short_player.dart';
import 'package:myapp/features/content/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import '../../../models/models.dart';

class ContentsList extends StatefulWidget {
  final List<Content> contents;
  final Function(int index)? onVideoChange;

  const ContentsList({
    super.key,
    required this.contents,
    this.onVideoChange,
  });

  @override
  State<ContentsList> createState() => _ContentsListState();
}

class _ContentsListState extends State<ContentsList> {
  late PageController _pageController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final progress = await SharedPref.getCurrProgress();

      final jumpTo = widget.contents.indexWhere(
        (content) =>
            content.speechExercise?.subLevel == progress?['subLevel'] &&
                content.speechExercise?.level == progress?['level'] ||
            content.video?.subLevel == progress?['subLevel'] &&
                content.video?.level == progress?['level'],
      );

      if (jumpTo >= widget.contents.length || jumpTo < 0) return;

      _isAnimating = true;
      await _pageController.animateToPage(jumpTo,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _isAnimating = false;
    });
  }

  @override
  void didUpdateWidget(covariant ContentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (oldWidget.contents.length == widget.contents.length) return;

      final progress = await SharedPref.getCurrProgress();
      final jumpTo = widget.contents.indexWhere(
        (content) =>
            content.speechExercise?.subLevel == progress?['subLevel'] &&
                content.speechExercise?.level == progress?['level'] ||
            content.video?.subLevel == progress?['subLevel'] &&
                content.video?.level == progress?['level'],
      );
      if (jumpTo >= widget.contents.length || jumpTo < 0) return;
      _pageController.jumpToPage(jumpTo);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      allowImplicitScrolling: true,
      itemCount: widget.contents.length + 1,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        if (_isAnimating) return;
        widget.onVideoChange?.call(index);
      },
      itemBuilder: (context, index) {
        final content = widget.contents.length > index ? widget.contents[index] : null;
        final isLastContent = index == widget.contents.length;

        if (isLastContent || content == null) {
          return LastLevelWidget(onRefresh: () {
            widget.onVideoChange?.call(index);
          });
        }

        return Stack(
          children: [
            Center(
              child: content.video != null
                  ? YtShortPlayer(
                      key: ValueKey('${content.video!.level}-${content.video!.subLevel}'),
                      videoId: content.video!.ytId,
                    )
                  : content.speechExercise != null
                      ? SpeechExerciseScreen(
                          key: ValueKey(
                            '${content.speechExercise!.level}-${content.speechExercise!.subLevel}',
                          ),
                          exercise: content.speechExercise!,
                        )
                      : const SizedBox.shrink(),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Level ${content.video?.level ?? content.speechExercise?.level}-${content.video?.subLevel ?? content.speechExercise?.subLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
