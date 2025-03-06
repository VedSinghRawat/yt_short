import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';

class YtPlayer extends ConsumerStatefulWidget {
  final String videoId;
  final String? uniqueId;

  final void Function(YoutubePlayerController controller)? onControllerInitialized;

  const YtPlayer({
    super.key,
    required this.videoId,
    this.uniqueId,
    this.onControllerInitialized,
  });

  @override
  ConsumerState<YtPlayer> createState() => _YtPlayerState();
}

class _YtPlayerState extends ConsumerState<YtPlayer> {
  late final YoutubePlayerController _controller;
  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;
  bool _isVisible = false;
  bool _isPlayerReady = false;
  bool _isDisposed = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
  }

  void _initializeYoutubePlayer() async {
    String videoId = widget.videoId;

    // Handle YouTube URLs by extracting video ID if needed
    if (videoId.contains('youtube.com') || videoId.contains('youtu.be')) {
      videoId = YoutubePlayerController.convertUrlToId(videoId) ?? videoId;
    }

    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: false,
        loop: true,
        showControls: false,
        showFullscreenButton: false,
        enableCaption: false,
      ),
    );

    // Load the video
    await _controller.loadVideoById(videoId: videoId);

    // Mark the player as ready after a short delay
    // This ensures the controller has properly initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed && mounted) {
        setState(() {
          _isPlayerReady = true;
        });
        widget.onControllerInitialized?.call(_controller);
        _handleVisibilityChange();
      }
    });

    // Set up fullscreen handling
    _controller.setFullScreenListener((_) {
      // Handle fullscreen changes if needed
    });

    // Listen to player value changes
    _controller.listen((event) {
      if (!_isPlayerReady || _isDisposed) return;

      // Check if video finished
      if (event.playerState == PlayerState.ended &&
          !ref.read(sublevelControllerProvider).hasFinishedVideo) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
      }

      // Update play/pause icon
      final isPlaying = event.playerState == PlayerState.playing;
      if (isPlaying != (_iconData == Icons.pause) && mounted) {
        setState(() {
          _iconData = isPlaying ? Icons.pause : Icons.play_arrow;
        });
      }
    });
  }

  void _reloadVideo() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed && mounted) {
        _controller.loadVideoById(videoId: widget.videoId);
      }
    });
  }

  void _changePlayingState() async {
    if (!_isPlayerReady) return;

    final playerState = await _controller.playerState;
    if (playerState == PlayerState.playing) {
      _controller.pauseVideo();
      setState(() {
        _iconData = Icons.play_arrow;
      });
    } else {
      _controller.playVideo();
      setState(() {
        _iconData = Icons.pause;
      });
    }

    if (mounted) {
      setState(() {
        _showPlayPauseIcon = true;
      });
    }

    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(milliseconds: _iconData == Icons.play_arrow ? 700 : 2000), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _handleVisibilityChange() {
    if (!_isPlayerReady || _isDisposed) return;

    if (_isVisible) {
      _controller.playVideo();
    } else {
      _controller.pauseVideo();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _isDisposed) return;

    final isVisible = info.visibleFraction > 0.6;

    if (_isVisible == isVisible) return;

    try {
      setState(() {
        _isVisible = isVisible;
      });

      _handleVisibilityChange();
    } catch (e) {
      // Silent error handling - no logs needed
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _iconTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoId),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        alignment: Alignment.center,
        children: [
          YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
            backgroundColor: Colors.black,
          ),
          GestureDetector(
            onTap: _changePlayingState,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              child: PlayPauseButton(
                showPlayPauseIcon: _showPlayPauseIcon,
                iconData: _iconData,
              ),
            ),
          ),
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
