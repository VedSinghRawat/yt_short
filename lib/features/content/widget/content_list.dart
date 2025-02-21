import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:myapp/features/content/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import '../../../models/models.dart';
import 'dart:developer' as dev;

class ContentsList extends StatefulWidget {
  final List<Content> contents;
  final Future<void> Function(int index, PageController controller)? onVideoChange;

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

  void _jumpToPage(Duration timeStamp) async {
    final progress = await SharedPref.getCurrProgress();

    final jumpTo = widget.contents.indexWhere(
      (content) =>
          (content.subLevel == progress?['subLevel'] && content.level == progress?['level']) ||
          (content.ytId == progress?['videoId']),
    );

    if (jumpTo >= widget.contents.length || jumpTo < 0) return;

    final jumpContent = widget.contents[jumpTo];

    _pageController.jumpToPage(jumpTo);

    await SharedPref.setCurrProgress(
      level: jumpContent.level,
      subLevel: jumpContent.subLevel,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback(_jumpToPage);
  }

  @override
  void didUpdateWidget(covariant ContentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contents.length == widget.contents.length) return;

    WidgetsBinding.instance.addPostFrameCallback(_jumpToPage);
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
      dragStartBehavior: DragStartBehavior.down,
      itemCount: widget.contents.length + 1,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) async {
        await widget.onVideoChange?.call(index, _pageController);
      },
      itemBuilder: (context, index) {
        final content = widget.contents.length > index ? widget.contents[index] : null;
        final isLastContent = index == widget.contents.length;

        if (isLastContent || content == null) {
          return LastLevelWidget(
              onRefresh: () => widget.onVideoChange?.call(index, _pageController));
        }

        final positionText = '${content.level}-${content.subLevel}';

        return Stack(
          children: [
            Center(
              child: content.isVideo
                  ? YtPlayer(
                      key: Key(positionText),
                      uniqueId: positionText,
                      ytVidId: content.ytId,
                    )
                  : content.isSpeechExercise
                      ? SpeechExerciseScreen(
                          key: Key(positionText),
                          uniqueId: positionText,
                          exercise: content.speechExercise!,
                        )
                      : const SizedBox.shrink(),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _LevelText(positionText: positionText),
            ),
          ],
        );
      },
    );
  }
}

class _LevelText extends StatelessWidget {
  final String positionText;

  const _LevelText({required this.positionText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Level $positionText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
