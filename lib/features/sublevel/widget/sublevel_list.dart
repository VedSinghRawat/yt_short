import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/core/widgets/video_player.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:myapp/features/speech_exercise/screen/speech_exercise_screen.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

class SublevelsList extends ConsumerStatefulWidget {
  final List<SubLevel> sublevels;
  final Set<String> loadingIds;
  final Future<void> Function(int index, PageController controller)? onVideoChange;

  const SublevelsList({
    super.key,
    required this.sublevels,
    this.onVideoChange,
    required this.loadingIds,
  });

  @override
  ConsumerState<SublevelsList> createState() => _SublevelsListState();
}

class _SublevelsListState extends ConsumerState<SublevelsList> {
  late PageController _pageController;

  void _jumpToPage(Duration timeStamp) async {
    final progress = await SharedPref.getValue(PrefKey.currProgress);

    final jumpTo = widget.sublevels.indexWhere(
      (sublevel) => (sublevel.index == progress?.subLevel && sublevel.level == progress?.level),
    );

    if (jumpTo >= widget.sublevels.length || jumpTo < 0) return;

    final jumpSublevel = widget.sublevels[jumpTo];

    _pageController.jumpToPage(jumpTo);

    await SharedPref.copyWith(
      PrefKey.currProgress,
      Progress(
        level: jumpSublevel.level,
        subLevel: jumpSublevel.index,
      ),
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
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.sublevels[0].level == 1) return;

        await Future.delayed(const Duration(seconds: 5));
      },
      child: PageView.builder(
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

          final isLoading = sublevel == null
              ? widget.loadingIds.isNotEmpty
              : widget.loadingIds.contains(sublevel.levelId);

          if ((isLastSublevel || sublevel == null) && !isLoading) {
            final error = ref.watch(sublevelControllerProvider).error;

            if (error == null) {
              return const Loader();
            }

            return ErrorPage(
              onRefresh: () => widget.onVideoChange?.call(index, _pageController),
              text: error,
              buttonText: 'Retry',
            );
          }

          if (sublevel == null) {
            return const Loader();
          }

          final positionText = '${sublevel.level}-${sublevel.index}';

          final url = ref
              .read(levelServiceProvider)
              .getUnzippedVideoPath(sublevel.levelId, sublevel.videoFilename);

          return Stack(
            children: [
              Center(
                child: sublevel.when(
                  video: (video) => Player(
                    key: Key(positionText),
                    uniqueId: positionText,
                    videoPath: url,
                  ),
                  speechExercise: (speechExercise) => SpeechExerciseScreen(
                    key: Key(positionText),
                    uniqueId: positionText,
                    exercise: speechExercise,
                    videoPath: url,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _LevelText(positionText: positionText),
              ),
            ],
          );
        },
      ),
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
