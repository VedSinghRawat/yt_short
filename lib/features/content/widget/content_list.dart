import 'package:flutter/material.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/yt_short_player.dart';
import 'package:myapp/features/content/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/models.dart';
import 'dart:developer' as developer;

class ContentsList extends StatefulWidget {
  final List<Content> contents;
  final Function(int index, PageController controller)? onVideoChange;

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
  int _currentPage = 0;
  final Set<String> _completedContentIds = {};

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
    await SharedPref.setCurrProgress(jumpContent.level, jumpContent.subLevel);
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

  void _handleContentCompletion(String contentId) {
    if (!_completedContentIds.contains(contentId)) {
      setState(() {
        _completedContentIds.add(contentId);
      });
    }
  }

  void _onControllerInitialized(YoutubePlayerController controller, String contentId) {
    var isRunning = true;

    controller.addListener(() {
      if (!isRunning) return;

      final videoDuration = controller.value.metaData.duration;
      final compareDuration = videoDuration.inSeconds - controller.value.position.inSeconds;

      if (controller.value.hasPlayed && videoDuration != Duration.zero && compareDuration <= 1) {
        _handleContentCompletion(contentId);
        isRunning = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      allowImplicitScrolling: true,
      itemCount: widget.contents.length + 1,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        setState(() => _currentPage = index);

        widget.onVideoChange?.call(index, _pageController);
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
                  ? YtShortPlayer(
                      key: ValueKey(positionText),
                      videoId: content.ytId,
                      onControllerInitialized: (controller) =>
                          _onControllerInitialized(controller, content.ytId),
                    )
                  : content.isSpeechExercise
                      ? SpeechExerciseScreen(
                          onControllerInitialized: (controller) =>
                              _onControllerInitialized(controller, content.ytId),
                          key: ValueKey(positionText),
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
              ),
            ),
          ],
        );
      },
    );
  }
}
