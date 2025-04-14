import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:flutter/foundation.dart'; // Import for listEquals

class Player extends ConsumerStatefulWidget {
  final String? videoLocalPath;
  final String? uniqueId;
  final String? videoUrl;
  final Function(VideoPlayerController controller)? onControllerInitialized;
  final List<Dialogue> dialogues;

  const Player({
    super.key,
    required this.videoLocalPath,
    this.uniqueId,
    this.onControllerInitialized,
    this.videoUrl,
    required this.dialogues,
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

  final _audioPlayer = AudioPlayer();
  List<Dialogue> _displayableDialogues = [];
  List<Dialogue> _sourceDialogues = []; // List to hold the source data (dummy or real)

  // --- Set to TRUE to test filtering with dummy data ---
  final bool _useDummyDialoguesForTesting = true;
  // --- Set to false to use actual data logic ---

  // Controller and state for ListWheelScrollView focus effect
  late FixedExtentScrollController _dialogueScrollController;
  int _selectedDialogueIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize scroll controller and listener
    _dialogueScrollController = FixedExtentScrollController();
    _dialogueScrollController.addListener(() {
      if (!mounted) return;
      final newIndex = _dialogueScrollController.selectedItem;
      if (_selectedDialogueIndex != newIndex) {
        setState(() {
          _selectedDialogueIndex = newIndex;
        });
      }
    });

    // --- Data setup (dummy or real) ---
    if (_useDummyDialoguesForTesting) {
      _sourceDialogues = [
        const Dialogue(
            text: "Dialogue at ~2.9s", time: 2.9, audioFilename: "dummy5.mp3", zipNum: 1),
        const Dialogue(
            text: "Dialogue at ~2.5s", time: 2.5, audioFilename: "dummy4.mp3", zipNum: 1),
        const Dialogue(
            text: "Dialogue at ~2.1s", time: 2.1, audioFilename: "dummy3.mp3", zipNum: 1),
        const Dialogue(
            text: "Dialogue at ~1.8s", time: 1.8, audioFilename: "dummy2.mp3", zipNum: 1),
        const Dialogue(
            text: "Dialogue at ~0.5s", time: 0.5, audioFilename: "dummy1.mp3", zipNum: 1),
      ];
      developer.log("Using dummy dialogues as source for testing filtering.");
    } else {
      // Use actual data from widget
      _sourceDialogues = widget.dialogues;
      developer.log("Using widget dialogues as source.");
    }

    // Initialize displayable dialogues based on the chosen source at time zero
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
    _audioPlayer.dispose();
    _dialogueScrollController.dispose(); // Dispose scroll controller
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

  Future<void> _playDialogueAudio(String audioFilename) async {
    try {
      await _audioPlayer.stop();

      final levelService = ref.read(levelServiceProvider);
      final basePath = levelService.dialogueAudioBaseDirPath;
      final filePath = '$basePath/$audioFilename';
      developer.log("Attempting to play audio: $filePath");

      final file = File(filePath);
      if (!await file.exists()) {
        developer.log("Audio file not found: $filePath");
        return;
      }

      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
      developer.log("Playing audio: $filePath");
    } catch (e) {
      developer.log("Error playing dialogue audio: $e");
    }
  }

  void _updateDisplayableDialogues(Duration currentPosition) {
    // Remove the check for the testing flag here
    // if (_useDummyDialoguesForTesting) return;
    if (!mounted) return;

    final currentSeconds = currentPosition.inSeconds.toDouble();

    // Filter the _sourceDialogues list (which is either dummy or real)
    final newDialogues = _sourceDialogues.where((d) => d.time <= currentSeconds).toList();

    // Sort descending by time
    newDialogues.sort((a, b) => b.time.compareTo(a.time));

    // Update state if the list content has changed
    if (!listEquals(_displayableDialogues, newDialogues)) {
      developer.log("Updating displayable dialogues. Count: ${newDialogues.length}");
      setState(() {
        _displayableDialogues = newDialogues;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlayerReady =
        _isInitialized && _controller != null && _controller!.value.isInitialized;
    final bool isPaused = isPlayerReady && !_controller!.value.isPlaying;
    final bool showDialogueArea = isPaused;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double standardDialogueHeight = screenHeight * 0.2;
    const double emptyDialogueHeight = 65.0;

    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoLocalPath ?? widget.videoUrl ?? ''),
      onVisibilityChanged: _onVisibilityChanged,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                Visibility(
                  visible: showDialogueArea,
                  child: Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
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
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                      ),
                      child: _displayableDialogues.isNotEmpty
                          ? Stack(
                              children: [
                                _buildDialogueList(
                                  dialogues: _displayableDialogues,
                                  standardHeight: standardDialogueHeight,
                                ),
                                // Top Gradient Overlay
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
                                            Colors.black.withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.9],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Bottom Gradient Overlay
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
                                            Colors.black.withOpacity(0.0),
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
          ),
          if (isPlayerReady)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, child) {
                if (value.duration > Duration.zero) {
                  return _VideoProgressBar(controller: _controller!);
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

  Widget _buildDialogueList({required List<Dialogue> dialogues, required double standardHeight}) {
    final double itemHeight = standardHeight / 3.0;

    return ListWheelScrollView.useDelegate(
      controller: _dialogueScrollController,
      itemExtent: itemHeight,
      diameterRatio: 2.5,
      perspective: 0.004,
      magnification: 1.3,
      useMagnifier: true,
      physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildListDelegate(
        children: List<Widget>.generate(
          dialogues.length,
          (index) {
            final dialogue = dialogues[index];
            final formattedTime = formatDurationMMSS(dialogue.time);
            final bool isSelected = index == _selectedDialogueIndex;
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    dialogue.text,
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      _playDialogueAudio(dialogue.audioFilename);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          },
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
  void didUpdateWidget(covariant _VideoProgressBar oldWidget) {
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
      } else {
        if (_isPlaying && !_animationController.isAnimating) {
          _animationController.repeat();
        }
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
      widget.controller.value;
      widget.controller.removeListener(_updateVideoState);
    } catch (e) {
      developer.log("Error removing listener from controller (likely disposed): $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controllerDisposed ? _lastValue : widget.controller.value;

    if (value == null || !value.isInitialized || value.duration <= Duration.zero) {
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

          if (_isPlaying && _playbackSpeed > 0 && _animationController.isAnimating) {
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
                top: 0,
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
