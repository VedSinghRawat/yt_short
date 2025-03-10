import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/util_classes.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

class SublevelsList extends StatefulWidget {
  final List<SubLevel> sublevels;
  final bool isLoading;
  final Future<void> Function(int index, PageController controller)? onVideoChange;
  final Map<String, Media> ytUrls;

  const SublevelsList({
    super.key,
    required this.sublevels,
    this.onVideoChange,
    required this.ytUrls,
    this.isLoading = false,
  });

  @override
  State<SublevelsList> createState() => _SublevelsListState();
}

class _SublevelsListState extends State<SublevelsList> {
  late PageController _pageController;

  void _jumpToPage(Duration timeStamp) async {
    final progress = await SharedPref.getCurrProgress();

    final jumpTo = widget.sublevels.indexWhere(
      (sublevel) =>
          (sublevel.subLevel == progress?['subLevel'] && sublevel.level == progress?['level']) ||
          (sublevel.ytId == progress?['videoId']),
    );

    if (jumpTo >= widget.sublevels.length || jumpTo < 0) return;

    final jumpSublevel = widget.sublevels[jumpTo];

    _pageController.jumpToPage(jumpTo);

    await SharedPref.setCurrProgress(
      level: jumpSublevel.level,
      subLevel: jumpSublevel.subLevel,
    );
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      allowImplicitScrolling: true,
      dragStartBehavior: DragStartBehavior.down,
      itemCount: widget.sublevels.length + 1,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) async {
        await widget.onVideoChange?.call(index, _pageController);
      },
      itemBuilder: (context, index) {
        final sublevel = widget.sublevels.length > index ? widget.sublevels[index] : null;
        final isLastSublevel = index == widget.sublevels.length;

        if ((isLastSublevel || sublevel == null) && !widget.isLoading) {
          return LastLevelWidget(
              onRefresh: () => widget.onVideoChange?.call(index, _pageController));
        }

        final positionText = '${sublevel?.level}-${sublevel?.subLevel}';

        final urls = widget.ytUrls[sublevel?.ytId ?? ''];

        if (urls == null || sublevel == null) {
          return const Loader();
        }

        return Stack(
          children: [
            Center(
              child: sublevel.isVideo
                  ? YtPlayer(
                      key: Key(positionText),
                      uniqueId: positionText,
                      audioUrl: urls.audio,
                      videoUrl: urls.video,
                    )
                  : sublevel.isSpeechExercise
                      ? SpeechExerciseScreen(
                          key: Key(positionText),
                          uniqueId: positionText,
                          exercise: sublevel.speechExercise!,
                          audioUrl: urls.audio,
                          videoUrl: urls.video,
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
