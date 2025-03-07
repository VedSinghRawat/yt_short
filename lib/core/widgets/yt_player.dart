import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/video_progress_bar.dart';
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
  bool _isControllerInitialized = false;

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
        enableJavaScript: false,
      ),
    );

    // Load the video
    await _controller.loadVideoById(videoId: videoId);

    // Set up a listener for player state changes to detect when the player is ready
    _controller.listen((event) async {
      if (!mounted) return;

      final playerState = await _controller.playerState;

      if (!_isControllerInitialized) {
        setState(() {
          _isControllerInitialized = true;
        });
        widget.onControllerInitialized?.call(_controller);
      }

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

  void _changePlayingState() async {
    if (!mounted) return;

    final playerState = await _controller.playerState;

    final isPlaying = playerState == PlayerState.playing;
    isPlaying ? _controller.pauseVideo() : _controller.playVideo();
    setState(() {
      _iconData = isPlaying ? Icons.pause : Icons.play_arrow;
    });

    if (mounted) {
      setState(() {
        _showPlayPauseIcon = true;
      });
    }

    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(milliseconds: _iconData == Icons.play_arrow ? 300 : 700), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _handleVisibilityChange() {
    if (!mounted) return;

    // _isVisible ? _controller.playVideo() : _controller.pauseVideo();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isVisible = info.visibleFraction > 0.75;

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
    _iconTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoId),
      onVisibilityChanged: _onVisibilityChanged,
      child: YoutubePlayerControllerProvider(
        controller: _controller,
        child: GestureDetector(
          onTap: _changePlayingState,
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 9 / 16,
                  backgroundColor: Colors.black,
                ),
                // Timeline bar positioned at the bottom
                _isControllerInitialized
                    ? Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: VideoProgressBar(controller: _controller),
                      )
                    : const SizedBox.shrink(),
                PlayPauseButton(
                  showPlayPauseIcon: _showPlayPauseIcon,
                  iconData: _iconData,
                ),
              ],
            ),
          ),
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
          size: 36.0,
          color: Colors.white,
        ),
      ),
    );
  }
}
