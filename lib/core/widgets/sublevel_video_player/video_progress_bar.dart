import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:developer' as developer;

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

class _VideoProgressBarState extends State<VideoProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  int _lastEstimatedPositionMs = 0;
  int _pausedPositionMs = 0;
  DateTime _lastUpdateTime = DateTime.now();
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        final estimatedProgress = _estimateCurrentProgress();

        if (_currentProgress != estimatedProgress) {
          setState(() {
            _currentProgress = estimatedProgress;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant VideoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    setState(() {
      if (oldWidget.isPlaying && !widget.isPlaying) {
        _pausedPositionMs = _lastEstimatedPositionMs;
      }

      if (!oldWidget.isPlaying && widget.isPlaying) {
        _lastUpdateTime = DateTime.now();
      }

      if (widget.currentPositionMs < 1000 && _pausedPositionMs != 0) {
        _lastUpdateTime = DateTime.now();
        _currentProgress = 0.0;
        _lastEstimatedPositionMs = 0;
        _pausedPositionMs = 0;
      }
    });

    widget.isPlaying ? _timerController.repeat() : _timerController.stop();
  }

  // Calculates progress based on position and duration in milliseconds
  double _calculateProgress(int positionMs, int durationMs) {
    if (durationMs <= 0) return 0.0;
    return min(1.0, max(0.0, positionMs / durationMs));
  }

  // Estimates progress based on the last known position and time elapsed
  double _estimateCurrentProgress() {
    if (!widget.isPlaying) {
      return _currentProgress;
    }

    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUpdateTime);
    final estimatedDeltaMs = timeSinceLastUpdate.inMilliseconds;
    int estimatedPositionMs = _pausedPositionMs + estimatedDeltaMs;

    // Clamp estimated position in milliseconds
    estimatedPositionMs = estimatedPositionMs.clamp(0, widget.durationMs);

    _lastEstimatedPositionMs = estimatedPositionMs;

    double estimatedProgress = _calculateProgress(estimatedPositionMs, widget.durationMs);
    return estimatedProgress;
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double displayProgress = _currentProgress;

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
          final double clampedProgress = displayProgress.clamp(0.0, 1.0);
          final double indicatorPosition = progressBarWidth * clampedProgress;
          final double clampedIndicatorPosition = indicatorPosition.clamp(0.0, progressBarWidth);

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 3,
                width: progressBarWidth,
                color: Colors.grey.withAlpha(128),
              ),
              Container(
                height: 3,
                width: clampedIndicatorPosition,
                color: Colors.red,
              ),
              Positioned(
                left: clampedIndicatorPosition - 5,
                top: (10 - 10) / 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
