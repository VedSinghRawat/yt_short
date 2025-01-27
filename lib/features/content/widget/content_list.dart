import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_short_player.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';

import '../../../models/models.dart';

class ContentsList extends StatefulWidget {
  final List<Content> stepList;
  final Function(int index)? onVideoChange;

  const ContentsList({
    super.key,
    required this.stepList,
    this.onVideoChange,
  });

  @override
  State<ContentsList> createState() => _ContentsListState();
}

class _ContentsListState extends State<ContentsList> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    int newPage = _pageController.page?.round() ?? 0;
    if (newPage == _currentPage) return;

    setState(() => _currentPage = newPage);
    widget.onVideoChange?.call(newPage);
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
      itemCount: widget.stepList.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        final content = widget.stepList[index];
    
        if (content.video != null) {
          return Center(
            child: YtShortPlayer(
              key: ValueKey('${content.video!.level}-${content.video!.subLevel}'),
              videoId: content.video!.ytId,
            ),
          );
        } else if (content.speechExercise != null) {
          return Center(
            child: SpeechExerciseScreen(
              key: ValueKey('${content.speechExercise!.level}-${content.speechExercise!.subLevel}'),
              exercise: content.speechExercise!,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
