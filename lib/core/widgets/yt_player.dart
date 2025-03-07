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

  // Video progress tracking
  double _currentPosition = 0;
  double _videoDuration = 0;
  StreamSubscription? _videoStateSubscription;

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

    // Mark the player as ready after a short delay
    // This ensures the controller has properly initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed && mounted) {
        setState(() {
          _isPlayerReady = true;
        });
        widget.onControllerInitialized?.call(_controller);
        _handleVisibilityChange();
        _startVideoStateTracking();
      }
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

  void _startVideoStateTracking() {
    // Initialize video duration (once)
    _updateVideoDuration();

    // Subscribe to video state stream for continuous updates
    _videoStateSubscription = _controller.videoStateStream.listen((state) {
      if (!_isDisposed && mounted) {
        setState(() {
          // Update current position from stream data
          _currentPosition = state.position.inSeconds.toDouble();
        });
      }
    }, onError: (error) {
      developer.log('Video state stream error: $error');
    });
  }

  Future<void> _updateVideoDuration() async {
    if (!_isPlayerReady || _isDisposed) return;

    try {
      final duration = await _controller.duration;
      if (mounted) {
        setState(() {
          _videoDuration = duration.toDouble();
        });
      }
    } catch (e) {
      developer.log('Error updating video duration: $e');
      // Silent error handling
    }
  }

  void _changePlayingState() async {
    if (!_isPlayerReady) return;

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
    _iconTimer = Timer(Duration(milliseconds: _iconData == Icons.play_arrow ? 700 : 1000), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _handleVisibilityChange() {
    if (!_isPlayerReady || _isDisposed) return;

    _isVisible ? _controller.playVideo() : _controller.pauseVideo();
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
    _videoStateSubscription?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoId),
      onVisibilityChanged: _onVisibilityChanged,
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressBar(
                  currentPosition: _currentPosition,
                  duration: _videoDuration,
                ),
              ),
              PlayPauseButton(
                showPlayPauseIcon: _showPlayPauseIcon,
                iconData: _iconData,
              ),
            ],
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

// Non-interactive timeline bar to show video progress
class VideoProgressBar extends StatelessWidget {
  final double currentPosition;
  final double duration;

  const VideoProgressBar({
    super.key,
    required this.currentPosition,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final progress = duration > 0 ? currentPosition / duration : 0.0;

    // YouTube red color
    const youtubeRed = Color(0xFFFF0000);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Background bar
        Container(
          height: 3,
          width: double.infinity,
          color: Colors.grey[400], // Lighter gray for background
        ),

        // Progress bar
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 3,
            color: youtubeRed, // YouTube red color
          ),
        ),

        // Circle indicator
        Positioned(
          left: progress.clamp(0.0, 1.0) * MediaQuery.of(context).size.width -
              4, // Adjusting for circle radius
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: youtubeRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
