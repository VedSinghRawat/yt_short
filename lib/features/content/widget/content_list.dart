import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:myapp/features/content/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import '../../../models/models.dart';

class ContentsList extends StatefulWidget {
  final List<Content> contents;
  final bool isLoading;
  final Future<void> Function(int index, PageController controller)? onVideoChange;
  final Map<String, Map<String, String>> ytUrls;

  const ContentsList({
    super.key,
    required this.contents,
    this.onVideoChange,
    required this.ytUrls,
    this.isLoading = false,
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

        if ((isLastContent || content == null) && !widget.isLoading) {
          return LastLevelWidget(
              onRefresh: () => widget.onVideoChange?.call(index, _pageController));
        }

        final positionText = '${content?.level}-${content?.subLevel}';

        final urls = widget.ytUrls[content?.ytId ?? ''];

        if (urls == null || content == null) {
          return const Loader();
        }

        return Stack(
          children: [
            Center(
              child: content.isVideo
                  ? YtPlayer(
                      key: Key(positionText),
                      uniqueId: positionText,
                      audioUrl: urls['audio']!,
                      videoUrl: urls['video']!,
                    )
                  : content.isSpeechExercise
                      ? SpeechExerciseScreen(
                          key: Key(positionText),
                          uniqueId: positionText,
                          exercise: content.speechExercise!,
                          audioUrl: urls['audio']!,
                          videoUrl: urls['video']!,
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
