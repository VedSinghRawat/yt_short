import 'package:flutter/material.dart';
import 'dart:math';

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

    _timerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..addListener(() {
      final estimatedProgress = _estimateCurrentProgress();

      if (_currentProgress != estimatedProgress) {
        setState(() {
          _currentProgress = estimatedProgress;
        });
      }
    });

    _lastEstimatedPositionMs = widget.currentPositionMs;
    _pausedPositionMs = widget.currentPositionMs;
  }

  @override
  void didUpdateWidget(covariant VideoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentPositionMs >= 0 && (widget.currentPositionMs - _lastEstimatedPositionMs).abs() > 500) {
      _lastEstimatedPositionMs = widget.currentPositionMs;
      _pausedPositionMs = widget.currentPositionMs;
      _lastUpdateTime = DateTime.now();

      setState(() {
        _currentProgress = _calculateProgress(widget.currentPositionMs, widget.durationMs);
      });
    }

    if (oldWidget.isPlaying && !widget.isPlaying) {
      setState(() {
        _pausedPositionMs = _lastEstimatedPositionMs;
      });
    }

    if (!oldWidget.isPlaying && widget.isPlaying) {
      setState(() {
        _lastUpdateTime = DateTime.now();
        // Only reset if position is explicitly set to 0 and we're not resuming from app lifecycle change
        if (widget.currentPositionMs == 0 && _pausedPositionMs == 0) {
          _lastEstimatedPositionMs = 0;
          _pausedPositionMs = 0;
        }
        _currentProgress = _estimateCurrentProgress();
      });
    }

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
      // When paused, use either the widget position (if valid) or our last estimate
      if (widget.currentPositionMs > 0) {
        _lastEstimatedPositionMs = widget.currentPositionMs;
        _pausedPositionMs = widget.currentPositionMs;
      }
      return _calculateProgress(_pausedPositionMs, widget.durationMs);
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
              Container(height: 3, width: progressBarWidth, color: Colors.grey.withAlpha(128)),
              Container(height: 3, width: clampedIndicatorPosition, color: Colors.red),
              Positioned(
                left: clampedIndicatorPosition - 5,
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
