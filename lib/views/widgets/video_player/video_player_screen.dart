import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/video/video.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/views/screens/error_screen.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/scroll_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/foundation.dart';
import 'video_progress_bar.dart';
import 'package:myapp/views/widgets/video_player/dialogue_popup.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Video video;
  final bool isCurrent;

  const VideoPlayerScreen({super.key, required this.video, required this.isCurrent});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends ConsumerState<VideoPlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Duration? _lastPosition;
  String? error;
  bool _isVisible = false;

  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;
  bool isFinished = false;
  bool _showDialogueArea = false;
  bool _isBuffering = false;

  // Animation-related variables
  bool _showAnimation = false;
  bool _showScrollIndicator = false;
  Timer? _animationTimer;
  Timer? _bounceTimer;

  List<VideoDialogue> _displayableDialogues = [];
  final GlobalKey _stackKey = GlobalKey();

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
    _animationTimer?.cancel();
    _bounceTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _controller?.removeListener(_listener);
      // Save the current position before pausing
      if (_controller != null && _controller!.value.isInitialized) {
        _lastPosition = _controller!.value.position;
      }
      await pause();
      await _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null) {
        await _initializeVideoPlayerController();
      } else if (_controller != null &&
          _controller!.value.isInitialized &&
          !_controller!.value.isPlaying &&
          _isVisible) {
        await play();
      }
    }
  }

  void _listener() {
    if (!mounted || _controller == null) return;

    final value = _controller!.value;
    if (!value.isInitialized) return;

    _updateDisplayableDialogues(value.position);

    // Check buffering state - but not when video is finished
    final position = value.position;
    final duration = value.duration;
    final isNearEnd = duration > Duration.zero && (duration - position).inMilliseconds <= 100;

    final isBuffering = value.isBuffering && !isNearEnd && !isFinished;
    if (_isBuffering != isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }

    if (value.hasError && error == null) {
      developer.log('error in video player ${value.errorDescription}');
      if (mounted) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);

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

    final timeRemaining = duration - position;

    // With 100ms updates, we can use a much smaller threshold for detecting video end
    bool shouldBeFinished = timeRemaining.inMilliseconds <= 100;

    isFinished = shouldBeFinished;

    if (isFinished && !ref.read(sublevelControllerProvider).hasFinishedSublevel) {
      ref.read(sublevelControllerProvider.notifier).setHasFinishedSublevel(true);
      _controller?.removeListener(_listener);

      // Start animation when video finishes (backup trigger)
      if (widget.isCurrent) {
        _startAnimationTimer();
      }
    }
  }

  void _changePlayingState({bool changeToPlay = true}) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final wasPlaying = _controller!.value.isPlaying;

    if (wasPlaying || !changeToPlay) {
      await pause();
      _updateDisplayableDialogues(_controller!.value.position);
    } else {
      if (_controller!.value.position >= _controller!.value.duration) {
        await seek(Duration.zero);
      }
      await play();
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
    if (_controller == null || !_controller!.value.isInitialized || !widget.isCurrent) return;
    await _controller!.play();

    setDialogueAreaAndAppBar(false);
  }

  Future<void> pause() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setDialogueAreaAndAppBar(true);

    await _controller!.pause();
  }

  void setDialogueAreaAndAppBar(bool value) {
    setState(() {
      _showDialogueArea = value;
    });

    // Set app bar visibility based on the value, same behavior for all devices
    ref.read(uIControllerProvider.notifier).setIsAppBarVisible(value);
  }

  Future<void> _handleVisibility(bool isVisible) async {
    if (_controller == null) return;

    if (!_controller!.value.isInitialized) return;

    if (isVisible) {
      _controller!.addListener(_listener);
      if (!_controller!.value.isPlaying && error == null && _controller!.value.isInitialized && widget.isCurrent) {
        await _controller!.play();
      }
    } else {
      if (_controller!.value.isPlaying && _controller!.value.isInitialized) {
        await _controller!.pause();
      }
      _controller!.removeListener(_listener);
    }

    if (mounted) {
      setState(() {
        _showDialogueArea = false;
      });
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
    if (mounted) {
      setState(() {
        error = null;
      });
    }

    await _controller?.dispose();
    _controller = null;

    try {
      String localPath = PathService.sublevelAsset(widget.video.levelId, widget.video.id, AssetType.video);

      if (!mounted) return;

      final urls =
          [BaseUrl.cloudflare, BaseUrl.s3]
              .map(
                (url) => ref
                    .read(sublevelControllerProvider.notifier)
                    .getAssetUrl(widget.video.levelId, widget.video.id, AssetType.video, url),
              )
              .toList();

      final file = FileService.getFile(localPath);
      final fileExists = await file.exists();
      if (!mounted) return;

      if (fileExists) {
        _controller = VideoPlayerController.file(file);
      } else if (urls.isNotEmpty) {
        try {
          _controller = VideoPlayerController.networkUrl(Uri.parse(urls[0]));
        } catch (e) {
          _controller = VideoPlayerController.networkUrl(Uri.parse(urls[1]));
        }
      }

      if (!mounted) return;

      _controller!.addListener(_listener);
      await _controller!.initialize();

      if (mounted) {
        setState(() {});
      }

      if (_lastPosition != null) {
        await seek(_lastPosition!);
        _lastPosition = null;
      }

      if (_isVisible && _controller!.value.isInitialized) {
        await play();
      }
    } catch (e) {
      developer.log('Error initializing video player ${widget.video.id}', error: e.toString());

      _controller?.removeListener(_listener);

      await _controller?.dispose();
      _controller = null;

      if (mounted) {
        setState(() {
          error = '$errorText: ${e.toString()}';
        });
      }
    }
  }

  String get errorText => choose(
    hindi: 'वीडियो शुरू नहीं हो पाया, कृपया थोड़ी देर बाद फिर से कोशिश करें।',
    hinglish: 'Video start nahi ho paya, kripya thodi der baad try karein.',
    lang: ref.read(langControllerProvider),
  );

  void _updateDisplayableDialogues(Duration currentPosition) {
    if (!mounted) return;
    final currentSeconds = currentPosition.inMilliseconds / 1000;

    final newDialogues = widget.video.dialogues.where((d) => d.time <= currentSeconds).toList();
    newDialogues.sort((a, b) => b.time.compareTo(a.time));

    if (listEquals(_displayableDialogues, newDialogues)) return;

    setState(() {
      _displayableDialogues = newDialogues;
    });
  }

  Future<void> seek(Duration newPosition) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.seekTo(newPosition);
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

  // Animation methods
  void _startAnimationTimer() {
    _animationTimer?.cancel();
    _bounceTimer?.cancel();

    setState(() {
      _showScrollIndicator = true;
    });

    int bounceCount = 0;
    const maxBounces = 6;

    _bounceTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _showAnimation = !_showAnimation;
      });

      bounceCount++;
      if (bounceCount >= maxBounces) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _showAnimation = false;
            _showScrollIndicator = false;
          });
        }
      }
    });

    _animationTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        setState(() {
          _showAnimation = false;
          _showScrollIndicator = false;
        });
        _animationTimer?.cancel();
      }
    });
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _bounceTimer?.cancel();
    if (mounted) {
      setState(() {
        _showAnimation = false;
        _showScrollIndicator = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlayerReady = _controller?.value.isInitialized ?? false;
    final progress = ref.watch(uIControllerProvider.select((state) => state.currentProgress));
    final responsiveness = ResponsivenessService(context);

    // Listen for app bar visibility changes to stop animation
    ref.listen(uIControllerProvider.select((value) => value.isAppBarVisible), (previous, isVisible) {
      if (isVisible) {
        _stopAnimation();
      }

      if (!isVisible && _showDialogueArea) {
        setState(() {
          _showDialogueArea = false;
        });
      }
    });

    // Animation is now handled directly in _listenerVideoFinished when video completes

    return VisibilityDetector(
      key: Key(widget.video.id + widget.video.index.toString()),
      onVisibilityChanged: _onVisibilityChanged,
      child: SafeArea(
        child: Builder(
          builder: (context) {
            final orientation = MediaQuery.of(context).orientation;
            return orientation == Orientation.landscape && responsiveness.screenType != Screen.mobile
                ? _buildTabletLandscapeLayout(isPlayerReady, progress, responsiveness)
                : _buildPortraitLayout(isPlayerReady, progress, responsiveness);
          },
        ),
      ),
    );
  }

  Widget _buildTabletLandscapeLayout(bool isPlayerReady, dynamic progress, ResponsivenessService responsiveness) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackWidth = constraints.maxWidth;
        final stackHeight = constraints.maxHeight;
        final videoHeight = stackHeight - 10; // Video takes full stack height minus padding only in landscape
        final videoWidth = videoHeight * (9 / 16); // Maintain 9:16 ratio

        // Calculate available space and dialogue width
        final availableSpace = stackWidth - videoWidth;
        final dialogueWidth = availableSpace * (2 / 3); // 2/3 of available space

        // Calculate video position - move left when dialogue is shown
        final videoLeftPosition =
            _showDialogueArea && _displayableDialogues.isNotEmpty
                ? (stackWidth - videoWidth - dialogueWidth) / 2
                : (stackWidth - videoWidth) / 2;

        return Stack(
          key: _stackKey,
          children: [
            // Video section - animated position
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: videoLeftPosition,
              top: 0,
              width: videoWidth,
              height: stackHeight,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                tween: Tween<double>(begin: 0, end: _showAnimation ? -30.0 : 0.0),
                builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildVideoPlayer(isPlayerReady, progress, responsiveness, true, videoWidth, videoHeight, null),
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
                          const VideoProgressBar(durationMs: 1, currentPositionMs: 0, isPlaying: false),
                      ],
                    ),
                    // Scroll indicator (moves with video)
                    if (_showScrollIndicator && widget.isCurrent)
                      const Positioned(bottom: 40, left: 0, right: 0, child: Center(child: ScrollIndicator())),
                  ],
                ),
              ),
            ),
            // Sliding dialogue section
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _showDialogueArea && _displayableDialogues.isNotEmpty ? 0 : -dialogueWidth,
              top: 0,
              bottom: 0,
              width: dialogueWidth,
              child: DialoguePopup(
                visible: true, // Always visible when positioned
                dialogues: _displayableDialogues,
                onClose: () async {
                  setState(() {
                    _showDialogueArea = false;
                  });
                  await play();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortraitLayout(bool isPlayerReady, dynamic progress, ResponsivenessService responsiveness) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackHeight = constraints.maxHeight - 10;

        return Stack(
          children: [
            // Single AnimatedPositioned that moves everything together
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              top: _showAnimation ? -30 : 0,
              left: 0,
              right: 0,
              bottom: _showAnimation ? 30 : 0,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Use same dimensions as mobile for portrait mode but constrained by stack height
                      _buildVideoPlayer(isPlayerReady, progress, responsiveness, false, null, null, stackHeight),
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
                        const VideoProgressBar(durationMs: 1, currentPositionMs: 0, isPlaying: false),
                    ],
                  ),
                  // Scroll indicator (moves with video)
                  if (_showScrollIndicator && widget.isCurrent)
                    const Positioned(bottom: 40, left: 0, right: 0, child: Center(child: ScrollIndicator())),
                ],
              ),
            ),
            DialoguePopup(
              visible: _showDialogueArea && _displayableDialogues.isNotEmpty,
              dialogues: _displayableDialogues,
              onClose: () async {
                setState(() {
                  _showDialogueArea = false;
                });
                await play();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoPlayer(
    bool isPlayerReady,
    dynamic progress,
    ResponsivenessService responsiveness,
    bool isTabletLandscape,
    double? width,
    double? height, [
    double? maxHeight,
  ]) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Responsive button positioning with increased gaps for tablets
    final buttonGap =
        isLandscape
            ? responsiveness.getResponsiveValues(mobile: 60.0, tablet: 60.0, largeTablet: 60.0)
            : responsiveness.getResponsiveValues(mobile: 60.0, tablet: 100.0, largeTablet: 150.0);

    // Responsive button sizing for portrait mode
    final buttonSize =
        isLandscape
            ? responsiveness.getResponsiveValues(mobile: 32.0, tablet: 32.0, largeTablet: 32.0)
            : responsiveness.getResponsiveValues(mobile: 32.0, tablet: 40.0, largeTablet: 48.0);

    final buttonPadding =
        isLandscape
            ? responsiveness.getResponsiveValues(mobile: 10.0, tablet: 10.0, largeTablet: 10.0)
            : responsiveness.getResponsiveValues(mobile: 10.0, tablet: 12.0, largeTablet: 16.0);

    // Calculate video dimensions with max height constraint for portrait
    double videoWidth = width ?? MediaQuery.of(context).size.width;
    double videoHeight = height ?? (MediaQuery.of(context).size.width * 16 / 9);

    // Apply max height constraint for portrait mode
    if (!isTabletLandscape && maxHeight != null) {
      if (videoHeight > maxHeight) {
        videoHeight = maxHeight;
        videoWidth = videoHeight * (9 / 16); // Recalculate width to maintain ratio
      }
    }

    return SafeArea(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (error != null)
            Center(child: Padding(padding: const EdgeInsets.all(8.0), child: ErrorPage(text: error!)))
          else if (isPlayerReady && _controller != null)
            GestureDetector(
              onTap: _changePlayingState,
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: AspectRatio(
                  aspectRatio: 9 / 16, // Always maintain 9:16 ratio
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            SizedBox(width: videoWidth, height: videoHeight, child: const Center(child: Loader())),

          if (isPlayerReady) ...[
            // Buffering loader overlay with touch pass-through
            IgnorePointer(
              ignoring: !_isBuffering, // Don't block touches when not buffering
              child: AnimatedOpacity(
                opacity: _isBuffering ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _isBuffering ? const Loader() : const SizedBox.shrink(),
              ),
            ),

            // Play/Pause button with fade animation and touch blocking fix
            IgnorePointer(
              ignoring: !_showPlayPauseIcon, // Don't block touches when invisible
              child: AnimatedOpacity(
                opacity: _showPlayPauseIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: .6),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    _iconData,
                    size: MediaQuery.of(context).size.width * 0.12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.replay_5, color: Colors.white, size: buttonSize),
                    onPressed: _seekBackward,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .3),
                      padding: EdgeInsets.all(buttonPadding),
                    ),
                  ),
                  SizedBox(width: buttonGap),
                  Visibility(
                    visible:
                        ref.watch(sublevelControllerProvider.select((s) => s.hasFinishedSublevel)) ||
                        isLevelAfter(
                          progress?.maxLevel ?? 1,
                          progress?.maxSubLevel ?? 1,
                          widget.video.level,
                          widget.video.index,
                        ),
                    child: IconButton(
                      icon: Icon(Icons.forward_5, color: Colors.white, size: buttonSize),
                      onPressed: _seekForward,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: .3),
                        padding: EdgeInsets.all(buttonPadding),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
