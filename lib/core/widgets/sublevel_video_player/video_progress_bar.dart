import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'dart:developer' as developer;

class VideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoProgressBar({super.key, required this.controller});

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> with SingleTickerProviderStateMixin {
  /// Controls a simple animation that runs when the video is playing.
  /// Its primary purpose is to trigger frequent [setState] calls,
  /// ensuring the progress bar updates smoothly even if the [VideoPlayerController]
  /// doesn't emit position updates frequently enough (e.g., every frame).
  late AnimationController _timerController;

  /// The last known [VideoPlayerValue] received from the controller.
  /// Used as the base for estimating the current position.
  VideoPlayerValue? _lastValue;

  /// The timestamp when [_lastValue] was received.
  /// Used to calculate the time elapsed since the last known position.
  DateTime _lastUpdateTime = DateTime.now();

  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    widget.controller.addListener(_updateVideoState);

    developer.log(' initState: Listener added and initial state set.');
  }

  /// Callback function triggered whenever the [VideoPlayerController]'s value changes.
  void _updateVideoState() {
    if (!mounted) return;

    if (!widget.controller.value.isInitialized) {
      developer.log(' _updateVideoState: Controller not initialized.');
      if (_timerController.isAnimating) {
        _timerController.stop();
        developer.log(' _updateVideoState: Timer stopped due to uninitialized controller.');
      }
      if (_lastValue != null) {
        setState(() {
          _lastValue = null;
        });
      }
      return;
    }

    final VideoPlayerValue currentValue = widget.controller.value;

    final bool changed = _lastValue == null ||
        _lastValue?.position != currentValue.position ||
        _lastValue?.duration != currentValue.duration ||
        _lastValue?.isPlaying != currentValue.isPlaying ||
        _lastValue?.playbackSpeed != currentValue.playbackSpeed ||
        _lastValue?.isBuffering != currentValue.isBuffering ||
        _lastValue?.hasError != currentValue.hasError;

    if (!changed) return;

    final bool shouldBePlaying = currentValue.isInitialized &&
        currentValue.isPlaying &&
        !currentValue.isBuffering &&
        !currentValue.hasError;

    setState(() {
      if (!shouldBePlaying) {
        developer.log(
          ' _updateVideoState: position changed: ${currentValue.position.inMilliseconds} lastValue: ${_lastValue?.position.inMilliseconds}',
        );
      }
      _lastValue = currentValue;
      _lastUpdateTime = DateTime.now();
    });

    shouldBePlaying ? _timerController.repeat() : _timerController.stop();
  }

  /// Estimates the current playback position based on the last known position
  /// and the time elapsed since that position was recorded.
  double _estimateCurrentProgress() {
    final Duration duration = _lastValue!.duration;
    final Duration basePosition = _lastValue!.position;
    final double playbackSpeed = _lastValue!.playbackSpeed;

    if (!_lastValue!.isPlaying) {
      developer.log(
        ' _estimateCurrentProgress: not playing: ${_lastValue!.position.inMilliseconds} lastProgress: $_lastProgress',
      );
      return _lastProgress;
    }

    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUpdateTime);

    final estimatedDeltaMs = (timeSinceLastUpdate.inMilliseconds * playbackSpeed).round();
    Duration estimatedPosition = basePosition + Duration(milliseconds: estimatedDeltaMs);

    if (estimatedPosition > duration) {
      estimatedPosition = duration;
    }
    if (estimatedPosition < Duration.zero) {
      estimatedPosition = Duration.zero;
    }

    final double estimatedProgress = (duration.inMilliseconds > 0)
        ? min(1.0, max(0.0, estimatedPosition.inMilliseconds / duration.inMilliseconds))
        : 0.0;

    setState(() {
      if (_lastProgress > estimatedProgress) {
        developer.log(
          ' _estimateCurrentProgress: estimatedProgress: $estimatedProgress lastProgress: $_lastProgress',
        );
      }

      _lastProgress = _lastProgress > estimatedProgress
          ? estimatedProgress < 0.1 && _lastProgress == 1.0
              ? estimatedProgress
              : _lastProgress
          : estimatedProgress;
    });

    return _lastProgress;
  }

  @override
  void dispose() {
    developer.log(' dispose: Cleaning up.');
    _timerController.dispose();
    widget.controller.removeListener(_updateVideoState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastValue == null ||
        !_lastValue!.isInitialized ||
        _lastValue!.duration <= Duration.zero ||
        _lastValue!.hasError) {
      return SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: 0,
          backgroundColor: Colors.grey.withAlpha(100),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red.withAlpha(150)),
        ),
      );
    }

    final double progress = _estimateCurrentProgress();

    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double progressBarWidth = constraints.maxWidth;
          final double indicatorPosition = progressBarWidth * progress;
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
