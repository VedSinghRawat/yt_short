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

class _PlayerState extends ConsumerState<Player> {
  VideoPlayerController? _controller;
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
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
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
        _iconData = _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow;
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

    final targetIcon = !isPlaying && changeToPlay ? Icons.pause : Icons.play_arrow;

    setState(() {
      _iconData = targetIcon;
      _showPlayPauseIcon = true;
    });

    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(milliseconds: targetIcon == Icons.play_arrow ? 700 : 2000), () {
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
          : VideoPlayerController.networkUrl(
              Uri.parse(
                widget.videoUrl!,
              ),
            );

      _controller!.addListener(_listener);

      await _controller!.setLooping(true);

      await _controller!.initialize();

      if (!mounted) {
        _controller?.removeListener(_listener);
        _controller?.dispose();
        return;
      }

      await _controller!.setLooping(true);

      setState(() {
        _isInitialized = true;
        error = null;
      });

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
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
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
