import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:myapp/features/speech_to_text/screen/speech_exercise_screen.dart';

import '../../../models/models.dart';

class SubLevelsList extends StatefulWidget {
  final List<SubLevel> stepList;
  final Function(int index)? onVideoChange;

  const SubLevelsList({
    super.key,
    required this.stepList,
    this.onVideoChange,
  });

  @override
  State<SubLevelsList> createState() => _SubLevelsListState();
}

class _SubLevelsListState extends State<SubLevelsList> {
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
        final subLevel = widget.stepList[index];

        if (subLevel.video != null) {
          return Center(
            child: YtPlayer(
              key: ValueKey(subLevel.video!.id),
              videoId: subLevel.video!.ytId,
            ),
          );
        } else if (subLevel.speechExercise != null) {
          return Center(
            child: SpeechExerciseScreen(
              key: ValueKey(subLevel.speechExercise!.id),
              exercise: subLevel.speechExercise!,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
