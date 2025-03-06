import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  late YoutubePlayerController _controller;
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

  void _initializeYoutubePlayer() {
    String videoId = widget.videoId;

    // Handle YouTube URLs by extracting video ID
    final extractedId = YoutubePlayer.convertUrlToId(videoId);
    if (extractedId != null) {
      videoId = extractedId;
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: false,
        disableDragSeek: false,
        loop: true,
        hideControls: true,
        enableCaption: false,
        hideThumbnail: false,
      ),
    );

    _controller.addListener(_youtubeListener);
  }

  void _youtubeListener() {
    if (!_isPlayerReady || _isDisposed) return;

    // Check if video finished
    if (_controller.value.playerState == PlayerState.ended &&
        !ref.read(sublevelControllerProvider).hasFinishedVideo) {
      ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
    }

    // Handle errors and retry if needed
    if (_controller.value.hasError && _retryCount < _maxRetries) {
      _retryCount++;
      _reloadVideo();
      return;
    }

    // Update play/pause icon
    if (_controller.value.isPlaying != (_iconData == Icons.pause)) {
      if (mounted) {
        setState(() {
          _iconData = _controller.value.isPlaying ? Icons.pause : Icons.play_arrow;
        });
      }
    }
  }

  void _reloadVideo() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed && mounted) {
        _controller.load(widget.videoId);
      }
    });
  }

  void _changePlayingState() {
    if (!_isPlayerReady) return;

    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }

    if (mounted) {
      setState(() {
        _iconData = _controller.value.isPlaying ? Icons.pause : Icons.play_arrow;
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
      _controller.play();
    } else {
      _controller.pause();
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
    _controller.removeListener(_youtubeListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoId),
      onVisibilityChanged: _onVisibilityChanged,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).colorScheme.primary,
          progressColors: ProgressBarColors(
            playedColor: Theme.of(context).colorScheme.primary,
            handleColor: Theme.of(context).colorScheme.primary,
          ),
          onReady: () {
            _isPlayerReady = true;
            widget.onControllerInitialized?.call(_controller);
            _handleVisibilityChange();
          },
          onEnded: (_) {
            // Ensure video completion is tracked
            if (!ref.read(sublevelControllerProvider).hasFinishedVideo) {
              ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
            }
          },
        ),
        builder: (context, player) {
          return GestureDetector(
            onTap: _changePlayingState,
            child: Stack(
              alignment: Alignment.center,
              children: [
                player,
                PlayPauseButton(showPlayPauseIcon: _showPlayPauseIcon, iconData: _iconData),
              ],
            ),
          );
        },
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
