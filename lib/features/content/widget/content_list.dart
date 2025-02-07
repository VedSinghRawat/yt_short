import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/yt_short_player.dart';
import 'package:myapp/features/content/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  int _currentPage = 0;
  final Set<String> _completedContentIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final progress = await SharedPref.getCurrProgress();

      final jumpTo = widget.contents.indexWhere(
        (content) =>
            (content.speechExercise?.subLevel == progress?['subLevel'] &&
                content.speechExercise?.level == progress?['level']) ||
            (content.video?.subLevel == progress?['subLevel'] &&
                content.video?.level == progress?['level']),
      );

      if (jumpTo >= widget.contents.length || jumpTo < 0) return;

      _currentPage = jumpTo;
      _completedContentIds.addAll(widget.contents
          .sublist(0, jumpTo)
          .map((content) => content.video?.ytId ?? content.speechExercise?.ytId ?? ''));

      _isAnimating = true;

      await _pageController.animateToPage(
        jumpTo,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
            (content.speechExercise?.subLevel == progress?['subLevel'] &&
                content.speechExercise?.level == progress?['level']) ||
            (content.video?.subLevel == progress?['subLevel'] &&
                content.video?.level == progress?['level']),
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
        if (_isAnimating) return;

        final isScrollingDown = index > _currentPage;

        if (isScrollingDown) {
          if (_currentPage >= widget.contents.length) return;

          final currentContent = widget.contents[_currentPage];
          final currentContentId =
              currentContent.video?.ytId ?? currentContent.speechExercise?.ytId;

          if (currentContentId == null || !_completedContentIds.contains(currentContentId)) {
            _isAnimating = true;
            _pageController
                .animateToPage(
                  _currentPage,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                )
                .then((_) => _isAnimating = false);

            showSnackBar(context, 'Please complete the current content before proceeding');
            return;
          }
        }

        setState(() => _currentPage = index);
        widget.onVideoChange?.call(index);
      },
      itemBuilder: (context, index) {
        final content = widget.contents.length > index ? widget.contents[index] : null;
        final isLastContent = index == widget.contents.length;

        if (isLastContent || content == null) {
          return LastLevelWidget(onRefresh: () => widget.onVideoChange?.call(index));
        }

        return Stack(
          children: [
            Center(
              child: content.video != null
                  ? YtShortPlayer(
                      // this is youtube_player_flutter custom widget
                      key: ValueKey('${content.video!.level}-${content.video!.subLevel}'),
                      videoId: content.video!.ytId,
                      onControllerInitialized: (controller) =>
                          _onControllerInitialized(controller, content.video!.ytId),
                    )
                  : content.speechExercise != null
                      ? SpeechExerciseScreen(
                          onControllerInitialized: (controller) =>
                              _onControllerInitialized(controller, content.speechExercise!.ytId),
                          key: ValueKey(
                              '${content.speechExercise!.level}-${content.speechExercise!.subLevel}'),
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
                  color: Colors.black.withOpacity(0.7),
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
