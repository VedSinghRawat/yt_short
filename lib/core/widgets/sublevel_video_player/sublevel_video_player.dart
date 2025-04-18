import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/foundation.dart'; // Import for listEquals
import 'dialogue_list.dart'; // Import the new dialogue list widget
import 'video_progress_bar.dart'; // Import the extracted progress bar

class SublevelVideoPlayer extends ConsumerStatefulWidget {
  final String? videoLocalPath;
  final String? uniqueId;
  final String? videoUrl;
  final Function(VideoPlayerController controller)? onControllerInitialized;
  final List<Dialogue> dialogues;

  const SublevelVideoPlayer({
    super.key,
    required this.videoLocalPath,
    this.uniqueId,
    this.onControllerInitialized,
    this.videoUrl,
    required this.dialogues,
  });

  @override
  ConsumerState<SublevelVideoPlayer> createState() => _SublevelVideoPlayerState();
}

class _SublevelVideoPlayerState extends ConsumerState<SublevelVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Duration? _lastPosition;
  bool _isInitialized = false;
  String? error;
  bool _isVisible = false;

  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;

  List<Dialogue> _displayableDialogues = [];

  @override
  void initState() {
    super.initState();

    _updateDisplayableDialogues(Duration.zero);
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

    // Always update displayable dialogues based on source list and current time
    _updateDisplayableDialogues(value.position);

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

    if (mounted && value.isPlaying != (_iconData == Icons.pause)) {
      setState(() {
        _iconData = value.isPlaying ? Icons.play_arrow : Icons.pause;
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
      // Explicitly update dialogues state after pausing
      _updateDisplayableDialogues(_controller!.value.position);
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

  void _updateDisplayableDialogues(Duration currentPosition) {
    if (!mounted) return;
    final currentSeconds = currentPosition.inSeconds.toDouble();

    final newDialogues = widget.dialogues.where((d) => d.time <= currentSeconds).toList();
    newDialogues.sort((a, b) => b.time.compareTo(a.time));

    if (listEquals(_displayableDialogues, newDialogues)) return;

    setState(() {
      _displayableDialogues = newDialogues;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlayerReady =
        _isInitialized && _controller != null && _controller!.value.isInitialized;
    final bool isPaused = isPlayerReady && !_controller!.value.isPlaying;
    final bool showDialogueArea = isPaused;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double standardDialogueHeight = screenHeight * 0.2;
    final double itemHeight = standardDialogueHeight / 3.0;
    const double emptyDialogueHeight = 65.0;

    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoLocalPath ?? widget.videoUrl ?? ''),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
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
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    else
                      const AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    PlayPauseButton(showPlayPauseIcon: _showPlayPauseIcon, iconData: _iconData),
                  ],
                ),
              ),
              Visibility(
                visible: showDialogueArea,
                child: Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: showDialogueArea,
                child: Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: _displayableDialogues.isNotEmpty
                        ? standardDialogueHeight
                        : emptyDialogueHeight,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                    ),
                    child: _displayableDialogues.isNotEmpty
                        ? Stack(
                            children: [
                              DialogueList(
                                dialogues: _displayableDialogues,
                                itemHeight: itemHeight,
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    height: standardDialogueHeight / 3.0,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          const BorderRadius.vertical(top: Radius.circular(16.0)),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black,
                                          Colors.black.withAlpha(0),
                                        ],
                                        stops: const [0.0, 0.9],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    height: standardDialogueHeight / 3.0,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black,
                                          Colors.black.withAlpha(0),
                                        ],
                                        stops: const [0.0, 0.9],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Text(
                              "No dialogue to show yet.",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (isPlayerReady)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, child) {
                if (value.duration > Duration.zero) {
                  return VideoProgressBar(
                    durationMs: value.duration.inMilliseconds,
                    currentPositionMs: value.position.inMilliseconds,
                    isPlaying: value.isPlaying,
                  );
                } else {
                  return const SizedBox(height: 10);
                }
              },
            )
          else
            const SizedBox(height: 10),
        ],
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
