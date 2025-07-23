import 'package:flutter/material.dart';

class VideoProgressBar extends StatefulWidget {
  final int durationMs;
  final int currentPositionMs;
  final bool isPlaying;

  const VideoProgressBar({
    super.key,
    required this.durationMs,
    required this.currentPositionMs,
    required this.isPlaying,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  double get _currentProgress {
    if (widget.durationMs <= 0) return 0.0;
    return (widget.currentPositionMs / widget.durationMs).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.durationMs <= 0) {
      return SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: 0,
          backgroundColor: Colors.grey.withAlpha(100),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.withAlpha(150)),
        ),
      );
    }

    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double progressBarWidth = constraints.maxWidth;
          final double indicatorPosition = progressBarWidth * _currentProgress;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 3, width: progressBarWidth, color: Colors.grey.withAlpha(128)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear,
                height: 3,
                width: indicatorPosition,
                color: Colors.red,
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear,
                left: indicatorPosition - 5,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
