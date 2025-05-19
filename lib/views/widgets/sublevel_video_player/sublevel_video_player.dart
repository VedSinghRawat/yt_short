import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/services/sublevel/sublevel_service.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/views/screens/error_page.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/foundation.dart'; // Import for listEquals
import 'dialogue_list.dart'; // Import the new dialogue list widget
import 'video_progress_bar.dart'; // Import the extracted progress bar

class SublevelVideoPlayer extends ConsumerStatefulWidget {
  final Function(VideoPlayerController controller, Function(Duration) seek)? onControllerInitialized;
  final bool stayPause;
  final SubLevel subLevel;

  const SublevelVideoPlayer({super.key, this.onControllerInitialized, this.stayPause = false, required this.subLevel});

  @override
  ConsumerState<SublevelVideoPlayer> createState() => _SublevelVideoPlayerState();
}

class _SublevelVideoPlayerState extends ConsumerState<SublevelVideoPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Duration? _lastPosition;
  String? error;
  bool _isVisible = false;
  bool _isInitializing = false;
  bool _isSeeking = false;

  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;
  bool isFinished = false;
  int? _lastTimeRemaining;

  List<Dialogue> _displayableDialogues = [];
  double? _dialogueListHeight;

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
      _controller?.removeListener(_listener);
      _controller?.pause();
      _lastPosition = _controller?.value.position;
      _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
          _isInitializing = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && !_isInitializing) {
        _initializeVideoPlayerController();
      } else if (_controller != null &&
          _controller!.value.isInitialized &&
          !_controller!.value.isPlaying &&
          !widget.stayPause &&
          _isVisible) {
        play();
      }
    }
  }

  void _listener() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;
    if (!value.isInitialized) return;

    _updateDisplayableDialogues(value.position);

    if (value.hasError && error == null) {
      developer.log('error in video player ${value.errorDescription}');
      if (mounted) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);

        setState(() {
          error = '$errorText: ${value.errorDescription ?? "Unknown error"}';
          _controller?.dispose();
        });
      }
    }

    _listenerVideoFinished();
  }

  void _listenerVideoFinished() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration <= Duration.zero) return;

    bool shouldBeFinished = false;
    final timeRemaining = duration - position;

    if (timeRemaining.inMilliseconds <= 600) {
      shouldBeFinished = true;
    }

    // Only check for backward jump if not in exercise mode, as seekTo(0) in exercises can trigger this.
    if (!_isSeeking && _lastTimeRemaining != null && timeRemaining.inMilliseconds > _lastTimeRemaining!) {
      shouldBeFinished = true;
    }

    _lastTimeRemaining = timeRemaining.inMilliseconds;

    isFinished = shouldBeFinished;

    if (isFinished && !ref.read(sublevelControllerProvider).hasFinishedVideo) {
      ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
      _controller?.removeListener(_listener);
    }
  }

  void _changePlayingState({bool changeToPlay = true}) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final wasPlaying = _controller!.value.isPlaying;

    if (wasPlaying || !changeToPlay) {
      await _controller!.pause();
      _updateDisplayableDialogues(_controller!.value.position);
    } else {
      if (_controller!.value.position >= _controller!.value.duration) {
        await seek(Duration.zero);
      }
      play();
    }

    final newIcon = wasPlaying ? Icons.pause : Icons.play_arrow;

    setState(() {
      _iconData = newIcon;
      _showPlayPauseIcon = true;
    });

    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(milliseconds: newIcon == Icons.pause ? 800 : 500), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  Future<void> play() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.play();
  }

  Future<void> _handleVisibility(bool isVisible) async {
    if (_controller == null || _isInitializing) return;

    if (!_controller!.value.isInitialized) return;

    if (isVisible) {
      _controller!.addListener(_listener);
      if (!_controller!.value.isPlaying && error == null && !widget.stayPause && _controller!.value.isInitialized) {
        await play();
      }
    } else {
      if (_controller!.value.isPlaying && _controller!.value.isInitialized) {
        await _controller!.pause();
      }
      _controller!.removeListener(_listener);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_controller == null) {
      if (mounted && _isVisible) {
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
    if (_isInitializing) return;

    if (mounted) {
      setState(() {
        _isInitializing = true;
        error = null;
      });
    }

    await _controller?.dispose();
    _controller = null;

    try {
      String localPath = PathService.videoLocal(widget.subLevel.levelId, widget.subLevel.videoFilename);

      final urls =
          [BaseUrl.cloudflare, BaseUrl.s3]
              .map(
                (url) => ref
                    .read(subLevelServiceProvider)
                    .getVideoUrl(widget.subLevel.levelId, widget.subLevel.videoFilename, url),
              )
              .toList();

      final file = File(localPath);

      if (await file.exists()) {
        _controller = VideoPlayerController.file(file);
      } else if (urls.isNotEmpty) {
        try {
          _controller = VideoPlayerController.networkUrl(Uri.parse(urls[0]));
        } catch (e) {
          _controller = VideoPlayerController.networkUrl(Uri.parse(urls[1]));
        }
      }

      _controller!.addListener(_listener);
      // await _controller!.setLooping(true);
      await _controller!.initialize();

      if (mounted) {
        setState(() {});
      }

      if (_lastPosition != null) {
        await seek(Duration.zero);
        _lastPosition = null;
      }

      if (_isVisible && !widget.stayPause && _controller!.value.isInitialized) {
        await play();
      }

      widget.onControllerInitialized?.call(_controller!, seek);
    } catch (e) {
      developer.log('Error initializing video player ${widget.subLevel.videoFilename}', error: e.toString());

      _controller?.removeListener(_listener);

      await _controller?.dispose();
      _controller = null;

      if (mounted) {
        setState(() {
          error = '$errorText: ${e.toString()}';
          _isInitializing = false;
        });
      }
    }
  }

  String get errorText => ref
      .read(langControllerProvider.notifier)
      .choose(
        hindi: 'वीडियो शुरू नहीं हो पाया, कृपया थोड़ी देर बाद फिर से कोशिश करें।',
        hinglish: 'Video start nahi ho paya, kripya thodi der baad try karein.',
      );

  void _updateDisplayableDialogues(Duration currentPosition) {
    if (!mounted) return;
    final currentSeconds = currentPosition.inSeconds.toDouble();

    final newDialogues = widget.subLevel.dialogues.where((d) => d.time <= currentSeconds).toList();
    newDialogues.sort((a, b) => b.time.compareTo(a.time));

    if (listEquals(_displayableDialogues, newDialogues)) return;

    setState(() {
      _displayableDialogues = newDialogues;
    });
  }

  Future<void> seek(Duration newPosition) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      _isSeeking = true;
    });
    await _controller!.seekTo(newPosition);
    setState(() {
      _isSeeking = false;
    });
  }

  Future<void> _seekBackward() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final currentPosition = _controller!.value.position;
    var newPosition = currentPosition - const Duration(seconds: 5);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }
    await seek(newPosition);
  }

  Future<void> _seekForward() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final currentPosition = _controller!.value.position;
    final duration = _controller!.value.duration;
    var newPosition = currentPosition + const Duration(seconds: 5);
    if (newPosition > duration) {
      newPosition = duration;
    }
    await seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlayerInitialized = _controller != null && _controller!.value.isInitialized;
    final bool isPlayerReady = isPlayerInitialized && !_isInitializing;

    final bool isPaused = isPlayerReady && !_controller!.value.isPlaying;
    final bool showDialogueArea = isPaused && _isVisible;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double standardDialogueHeight = screenHeight * 0.3;

    final double currentDialogueContainerHeight = _dialogueListHeight ?? standardDialogueHeight;

    return VisibilityDetector(
      key: Key(widget.subLevel.videoFilename + widget.subLevel.index.toString()),
      onVisibilityChanged: _onVisibilityChanged,
      child: SafeArea(
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
                        Center(child: Padding(padding: const EdgeInsets.all(8.0), child: ErrorPage(text: error!)))
                      else if (isPlayerReady)
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      else
                        const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator())),
                      PlayPauseButton(showPlayPauseIcon: _showPlayPauseIcon, iconData: _iconData),
                      Positioned(
                        left: 100,
                        bottom: 16,
                        child: IconButton(
                          icon: const Icon(Icons.replay_5, color: Colors.white, size: 30),
                          onPressed: _seekBackward,
                          style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.3)),
                        ),
                      ),
                      Positioned(
                        right: 100,
                        bottom: 16,
                        child: Visibility(
                          visible: ref.watch(sublevelControllerProvider.select((s) => s.hasFinishedVideo)),
                          child: IconButton(
                            icon: const Icon(Icons.forward_5, color: Colors.white, size: 30),
                            onPressed: _seekForward,
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: showDialogueArea,
                  child: Positioned.fill(
                    child: IgnorePointer(child: Container(color: Colors.black.withAlpha((255 * 0.25).round()))),
                  ),
                ),
                Visibility(
                  visible: showDialogueArea,
                  child: Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: currentDialogueContainerHeight,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                      ),
                      child: DialogueList(
                        dialogues: _displayableDialogues,
                        onHeightCalculated: (height) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _dialogueListHeight != height) {
                              setState(() => _dialogueListHeight = height * 3);
                            }
                          });
                        },
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
      ),
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key, required bool showPlayPauseIcon, required IconData iconData})
    : _showPlayPauseIcon = showPlayPauseIcon,
      _iconData = iconData;

  final bool _showPlayPauseIcon;
  final IconData _iconData;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showPlayPauseIcon ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(20),
        child: Icon(
          _iconData,
          size: MediaQuery.of(context).size.width * 0.12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
