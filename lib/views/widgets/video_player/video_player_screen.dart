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
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/views/screens/error_screen.dart';

import 'package:myapp/views/widgets/loader.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter/foundation.dart';
import 'video_progress_bar.dart';
import 'package:myapp/views/widgets/video_player/dialogue_popup.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

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

  List<VideoDialogue> _displayableDialogues = [];

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
    if (_controller == null || !_controller!.value.isInitialized) return;
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

    ref.read(uIControllerProvider.notifier).setIsAppBarVisible(value);
  }

  Future<void> _handleVisibility(bool isVisible) async {
    if (_controller == null) return;

    if (!_controller!.value.isInitialized) return;

    if (isVisible) {
      _controller!.addListener(_listener);
      if (!_controller!.value.isPlaying && error == null && _controller!.value.isInitialized) {
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

  @override
  Widget build(BuildContext context) {
    final bool isPlayerReady = _controller?.value.isInitialized ?? false;
    final progress = ref.watch(uIControllerProvider.select((state) => state.currentProgress));

    return VisibilityDetector(
      key: Key(widget.video.id + widget.video.index.toString()),
      onVisibilityChanged: _onVisibilityChanged,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (error != null)
                      Center(child: Padding(padding: const EdgeInsets.all(8.0), child: ErrorPage(text: error!)))
                    else if (isPlayerReady && _controller != null)
                      GestureDetector(
                        onTap: _changePlayingState,
                        child: AspectRatio(
                          aspectRatio: _controller?.value.aspectRatio ?? 9 / 16,
                          child: Stack(alignment: Alignment.center, children: [VideoPlayer(_controller!)]),
                        ),
                      )
                    else
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width * 16 / 9,
                        child: const Center(child: Loader()),
                      ),

                    if (isPlayerReady) ...[
                      PlayPauseButton(showPlayPauseIcon: _showPlayPauseIcon, iconData: _iconData),

                      Positioned(
                        left: 100,
                        bottom: 16,
                        child: IconButton(
                          icon: const Icon(Icons.replay_5, color: Colors.white, size: 30),
                          onPressed: _seekBackward,
                          style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: .3)),
                        ),
                      ),
                      Positioned(
                        right: 100,
                        bottom: 16,
                        child: Visibility(
                          visible:
                              ref.watch(sublevelControllerProvider.select((s) => s.hasFinishedSublevel)) ||
                              isLevelAfter(
                                progress?.maxLevel ?? 1,
                                progress?.maxSubLevel ?? 1,
                                widget.video.level,
                                widget.video.index,
                              ),
                          child: IconButton(
                            icon: const Icon(Icons.forward_5, color: Colors.white, size: 30),
                            onPressed: _seekForward,
                            style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: .3)),
                          ),
                        ),
                      ),
                    ],
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
                  const VideoProgressBar(durationMs: 1, currentPositionMs: 0, isPlaying: false),
              ],
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
    );
  }
}
