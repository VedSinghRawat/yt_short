import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Player extends ConsumerStatefulWidget {
  final String? videoLocalPath;
  final String? uniqueId;
  final String? videoUrl;
  final Function(VideoPlayerController controller)? onControllerInitialized;

  const Player({
    super.key,
    required this.videoLocalPath,
    this.uniqueId,
    this.onControllerInitialized,
    this.videoUrl,
  });

  @override
  ConsumerState<Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<Player> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Duration? _lastPosition;
  bool _isInitialized = false;
  String? error;
  bool _isVisible = false;

  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iconTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Store position before pausing/disposing
      _controller?.removeListener(_listener);
      _controller?.pause();
      _lastPosition = _controller?.value.position;
      _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _showPlayPauseIcon = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      developer.log("App resumed, initializing video controller.");
      // Only initialize if controller is null (disposed)
      if (_controller == null) {
        _initializeVideoPlayerController();
      }
    }
  }

  void _listener() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;
    if (!value.isInitialized) return;

    if (value.hasError && error == null) {
      developer.log('error in video player ${value.errorDescription}');
      if (mounted) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
        setState(() {
          error = 'Playback failed: ${value.errorDescription ?? "Unknown error"}';
          _isInitialized = false;
        });
      }
    }

    _listenerVideoFinished();

    if (mounted && _controller!.value.isPlaying != (_iconData == Icons.pause)) {
      // This might fight with the timed icon, consider if needed
      setState(() {
        _iconData = _controller!.value.isPlaying ? Icons.play_arrow : Icons.pause;
      });
    }
  }

  void _listenerVideoFinished() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration > Duration.zero) {
      final bool isNearEnd = (duration - position).inSeconds <= 1;
      if (isNearEnd && !ref.read(sublevelControllerProvider).hasFinishedVideo) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
        _controller?.removeListener(_listener);
      }
    }
  }

  void _changePlayingState({bool changeToPlay = true}) async {
    if (_controller == null || !_isInitialized) return;

    final isPlaying = _controller!.value.isPlaying;

    if (isPlaying || !changeToPlay) {
      await _controller!.pause();
    } else {
      if (_controller!.value.position >= _controller!.value.duration) {
        await _controller!.seekTo(Duration.zero);
      }
      await _controller!.play();
    }

    final targetIcon = !isPlaying && changeToPlay ? Icons.play_arrow : Icons.pause;

    setState(() {
      _iconData = targetIcon;
      _showPlayPauseIcon = true;
    });

    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(milliseconds: targetIcon == Icons.play_arrow ? 500 : 800), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _handleVisibility(bool isVisible) {
    if (_controller == null || !_isInitialized) return;

    if (isVisible) {
      _controller!.addListener(_listener);
      if (!_controller!.value.isPlaying && error == null) {
        _controller!.play();
      }
    } else {
      _controller!.pause();
      _controller!.removeListener(_listener);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_controller == null) {
      // Handle case where controller is disposed (e.g., app paused) while visibility changes
      developer.log("Visibility changed but controller is null.");
      if (mounted && _isVisible) {
        // If it was visible, update state
        setState(() {
          _isVisible = false;
        });
      }
      return;
    }

    if (!mounted) return;

    final isNowVisible = info.visibleFraction > 0.8;

    if (_isVisible == isNowVisible) return;

    setState(() {
      _isVisible = isNowVisible;
    });

    try {
      if (_isVisible && error != null) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
      }
      _handleVisibility(_isVisible);
    } catch (e) {
      developer.log('Error in Player._onVisibilityChanged', error: e.toString());
      if (mounted && error == null) {
        setState(() {
          error = 'Error handling visibility: $e';
        });
      }
    }
  }

  Future<void> _initializeVideoPlayerController() async {
    if (!mounted) return;

    try {
      final file = widget.videoLocalPath != null ? File(widget.videoLocalPath!) : null;

      if (file != null && !await file.exists()) {
        throw Exception("Video file not found at ${widget.videoLocalPath}");
      }

      _controller = file != null
          ? VideoPlayerController.file(file)
          : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));

      _controller!.addListener(_listener);
      await _controller!.setLooping(true);
      await _controller!.initialize();

      setState(() {
        _isInitialized = true;
        error = null;
      });

      if (_lastPosition != null) {
        await _controller!.seekTo(_lastPosition!);
        _lastPosition = null;
      }

      // Auto-play if visible after initialization/resuming
      if (_isVisible) {
        _controller!.play();
      }

      widget.onControllerInitialized?.call(_controller!);
    } catch (e) {
      developer.log('Error initializing video player', error: e.toString());
      _controller?.removeListener(_listener);
      if (mounted) {
        setState(() {
          error = "Error initializing video: ${e.toString()}";
          _isInitialized = false;
        });
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlayerReady = _isInitialized && _controller != null;

    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoLocalPath ?? widget.videoUrl ?? ''),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _changePlayingState,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ErrorPage(
                    text: error!,
                  ),
                ),
              )
            else if (isPlayerReady)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller!,
                    builder: (context, value, child) {
                      if (value.duration > Duration.zero) {
                        return _VideoProgressBar(controller: _controller!);
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),
            PlayPauseButton(showPlayPauseIcon: _showPlayPauseIcon, iconData: _iconData),
          ],
        ),
      ),
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required bool showPlayPauseIcon,
    required IconData iconData,
  })  : _showPlayPauseIcon = showPlayPauseIcon,
        _iconData = iconData;

  final bool _showPlayPauseIcon;
  final IconData _iconData;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showPlayPauseIcon ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(20),
        child: Icon(
          _iconData,
          size: MediaQuery.of(context).size.width * 0.12,
          color: Colors.white,
        ),
      ),
    );
  }
}

// New stateful widget for smoother progress bar updates using AnimationController
class _VideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoProgressBar({required this.controller});

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<_VideoProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Duration _lastKnownPosition = Duration.zero;
  Duration _lastKnownDuration = Duration.zero;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  DateTime _lastUpdateTime = DateTime.now();
  VideoPlayerValue? _lastValue;
  bool _controllerDisposed = false; // Track if the controller was disposed

  @override
  void initState() {
    super.initState();
    // Use an AnimationController to trigger frequent rebuilds for smooth progress
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Doesn't really matter for repeat
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    // Listen to the controller's playing state to start/stop the ticker
    widget.controller.addListener(_updateVideoState);
    // Initialize state
    _updateVideoState();
  }

  @override
  void didUpdateWidget(covariant _VideoProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller instance changes, remove old listener and add new one
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_updateVideoState);
      widget.controller.addListener(_updateVideoState);
    }
  }

  void _updateVideoState() {
    if (!mounted || _controllerDisposed) return;

    try {
      final value = widget.controller.value;
      _lastValue = value; // Store the last valid value

      final bool isCurrentlyPlaying = value.isPlaying;
      if (_isPlaying != isCurrentlyPlaying) {
        setState(() {
          _isPlaying = isCurrentlyPlaying;
          _lastUpdateTime = DateTime.now(); // Reset time on play/pause change

          if (_isPlaying && !_animationController.isAnimating) {
            _animationController.repeat();
          } else if (!_isPlaying && _animationController.isAnimating) {
            _animationController.stop();
          }
        });
      } else {
        // If playing state hasn't changed, but the controller is playing,
        // ensure the ticker is running (might have stopped erroneously)
        if (_isPlaying && !_animationController.isAnimating) {
          _animationController.repeat();
        }
      }

      // Update position/duration state only if necessary (less frequent updates)
      if (_lastKnownPosition != value.position ||
          _lastKnownDuration != value.duration ||
          _playbackSpeed != value.playbackSpeed) {
        setState(() {
          _lastKnownPosition = value.position;
          _lastKnownDuration = value.duration;
          _playbackSpeed = value.playbackSpeed;
          _lastUpdateTime = DateTime.now(); // Also update time when position/duration changes
        });
      }
    } catch (e) {
      developer.log("Error accessing controller value in _updateVideoState (likely disposed): $e");
      _controllerDisposed = true; // Mark as disposed
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      if (mounted) {
        setState(() {
          // Reset state or show an indicator if needed
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Safely remove listener
    try {
      // Check if the controller is still valid before removing listener
      widget.controller.value; // Throws if disposed
      widget.controller.removeListener(_updateVideoState);
    } catch (e) {
      developer.log("Error removing listener from controller (likely disposed): $e");
      // No need to set _controllerDisposed here as the widget is disposing anyway
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the last known value if the controller is disposed or has an error
    final value = _controllerDisposed ? _lastValue : widget.controller.value;

    // Handle cases where value might still be null or uninitialized
    if (value == null || !value.isInitialized || value.duration <= Duration.zero) {
      return const SizedBox(
        height: 10, // Maintain height even when bar isn't showing
        child: LinearProgressIndicator(
          // Show a generic loading indicator
          value: 0,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    // Removed Positioned wrapper, Column handles placement now
    return SizedBox(
      height: 10, // Height for the bar and circle area
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Access controller via widget.controller in StatefulWidget
          Duration currentPosition = _lastKnownPosition;
          final duration = _lastKnownDuration;

          // Estimate position based on time elapsed since last update
          if (_isPlaying && _playbackSpeed > 0 && _animationController.isAnimating) {
            final now = DateTime.now();
            final elapsed = now.difference(_lastUpdateTime);
            final estimatedDelta =
                Duration(milliseconds: (elapsed.inMilliseconds * _playbackSpeed).round());
            currentPosition += estimatedDelta;
          }

          // Clamp position between 0 and duration
          if (currentPosition > duration) {
            currentPosition = duration;
          }
          if (currentPosition < Duration.zero) {
            currentPosition = Duration.zero;
          }

          final durationMs = duration.inMilliseconds;
          final positionMs = currentPosition.inMilliseconds;

          // Avoid division by zero and handle invalid states
          final double progress = (durationMs > 0 && positionMs <= durationMs && positionMs >= 0)
              ? positionMs / durationMs
              : 0.0;
          // Ensure progress is clamped between 0.0 and 1.0
          final double clampedProgress = progress.clamp(0.0, 1.0);

          final double progressBarWidth = constraints.maxWidth;
          final double indicatorPosition =
              progressBarWidth * clampedProgress; // Use clampedProgress

          // Ensure indicator position is within bounds (redundant due to clampedProgress, but safe)
          final double clampedIndicatorPosition = indicatorPosition.clamp(0.0, progressBarWidth);

          return Stack(
            clipBehavior: Clip.none, // Allow circle to overflow slightly
            alignment: Alignment.centerLeft, // Align children to the start
            children: [
              // Background for the bar
              Container(
                height: 3,
                width: progressBarWidth,
                color: Colors.grey.withAlpha(128), // 0.5 opacity = 128 alpha (0.5 * 255)
              ),
              // Actual Progress (smoothness from AnimationController)
              Container(
                height: 3,
                width: clampedIndicatorPosition,
                color: Colors.red,
              ),
              // Indicator Circle (smoothness from AnimationController)
              Positioned(
                left: clampedIndicatorPosition - 5, // Center the circle on the progress point
                top: 0, // Adjust to center the circle vertically on the line ( (10-3)/2 = 3.5 )
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
