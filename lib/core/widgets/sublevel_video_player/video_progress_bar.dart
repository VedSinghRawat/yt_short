import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;

class VideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoProgressBar({super.key, required this.controller}); // Added super.key

  @override
  State<VideoProgressBar> createState() => VideoProgressBarState(); // Changed class name
}

class VideoProgressBarState extends State<VideoProgressBar> with SingleTickerProviderStateMixin {
  // Changed class name
  late AnimationController _animationController;
  Duration _lastKnownPosition = Duration.zero;
  Duration _lastKnownDuration = Duration.zero;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  DateTime _lastUpdateTime = DateTime.now();
  VideoPlayerValue? _lastValue;
  bool _controllerDisposed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    widget.controller.addListener(_updateVideoState);
    _updateVideoState();
  }

  @override
  void didUpdateWidget(covariant VideoProgressBar oldWidget) {
    // Changed type here
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_updateVideoState);
      widget.controller.addListener(_updateVideoState);
    }
  }

  void _updateVideoState() {
    if (!mounted || _controllerDisposed) return;

    try {
      final value = widget.controller.value;
      _lastValue = value;

      final bool isCurrentlyPlaying = value.isPlaying;
      if (_isPlaying != isCurrentlyPlaying) {
        setState(() {
          _isPlaying = isCurrentlyPlaying;
          _lastUpdateTime = DateTime.now();

          if (_isPlaying && !_animationController.isAnimating) {
            _animationController.repeat();
          } else if (!_isPlaying && _animationController.isAnimating) {
            _animationController.stop();
          }
        });
      }

      if (_lastKnownPosition != value.position ||
          _lastKnownDuration != value.duration ||
          _playbackSpeed != value.playbackSpeed) {
        setState(() {
          _lastKnownPosition = value.position;
          _lastKnownDuration = value.duration;
          _playbackSpeed = value.playbackSpeed;
          _lastUpdateTime = DateTime.now();
        });
      }
    } catch (e) {
      developer.log("Error accessing controller value in _updateVideoState (likely disposed): $e");
      _controllerDisposed = true;
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    try {
      // Check if controller is still valid before accessing value or removing listener
      if (!_controllerDisposed && widget.controller.value.isInitialized) {
        widget.controller.removeListener(_updateVideoState);
      }
    } catch (e) {
      developer.log("Error removing listener from controller (likely disposed): $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use _lastValue if controller is disposed, otherwise access controller value directly
    final value = _controllerDisposed
        ? _lastValue
        : (widget.controller.value.isInitialized ? widget.controller.value : null);

    if (value == null || value.duration <= Duration.zero) {
      return const SizedBox(
        height: 10,
        child: LinearProgressIndicator(
          value: 0,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Duration currentPosition = _lastKnownPosition;
          final duration = _lastKnownDuration;

          // Only estimate position if playing and controller isn't disposed
          if (_isPlaying &&
              !_controllerDisposed &&
              _playbackSpeed > 0 &&
              _animationController.isAnimating) {
            final now = DateTime.now();
            final elapsed = now.difference(_lastUpdateTime);
            final estimatedDelta =
                Duration(milliseconds: (elapsed.inMilliseconds * _playbackSpeed).round());
            currentPosition += estimatedDelta;
          }

          if (currentPosition > duration) {
            currentPosition = duration;
          }
          if (currentPosition < Duration.zero) {
            currentPosition = Duration.zero;
          }

          final durationMs = duration.inMilliseconds;
          final positionMs = currentPosition.inMilliseconds;

          final double progress = (durationMs > 0 && positionMs <= durationMs && positionMs >= 0)
              ? positionMs / durationMs
              : 0.0;
          final double clampedProgress = progress.clamp(0.0, 1.0);

          final double progressBarWidth = constraints.maxWidth;
          final double indicatorPosition = progressBarWidth * clampedProgress;

          // Clamp indicator position to prevent overflow
          final double clampedIndicatorPosition = indicatorPosition.clamp(0.0, progressBarWidth);

          return Stack(
            clipBehavior: Clip.none, // Allow the indicator circle to overflow
            alignment: Alignment.centerLeft,
            children: [
              // Background track
              Container(
                height: 3,
                width: progressBarWidth,
                color: Colors.grey.withAlpha(128),
              ),
              // Progress track
              Container(
                height: 3,
                width: clampedIndicatorPosition,
                color: Colors.red,
              ),
              // Indicator circle
              Positioned(
                left: clampedIndicatorPosition - 5, // Center the circle on the progress end
                top: (10 - 10) / 2, // Center vertically (height 10 - circle height 10) / 2 = 0
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
