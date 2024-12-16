import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

class YoutubeShort extends StatefulWidget {
  final String videoId;

  const YoutubeShort({
    super.key,
    required this.videoId,
  });

  @override
  State<YoutubeShort> createState() => _YoutubeShortState();
}

class _YoutubeShortState extends State<YoutubeShort> with AutomaticKeepAliveClientMixin {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  bool _isLoading = true;
  bool _isVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    setState(() => _isLoading = true);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: false,
        enableCaption: false,
        controlsVisibleAtStart: false,
        useHybridComposition: true,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller?.value.isReady == true && _isLoading) {
      setState(() {
        _isPlayerReady = true;
        _isLoading = false;
      });
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    bool visible = info.visibleFraction > 0.5;
    if (_isVisible != visible) {
      setState(() => _isVisible = visible);
      if (_controller != null && _isPlayerReady) {
        if (visible) {
          _controller!.play();
        } else {
          _controller!.pause();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key('youtube_short_${widget.videoId}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Stack(
          children: [
            if (_controller != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.red,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.red,
                      handleColor: Colors.redAccent,
                    ),
                    aspectRatio: 9 / 16,
                    onReady: () {
                      setState(() => _isPlayerReady = true);
                      // Only autoplay if the widget is currently visible
                      if (_isVisible) {
                        _controller!.play();
                      }
                    },
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),

            // Video controls overlay
            if (_isPlayerReady)
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.favorite_border,
                      'Like',
                      () => print('Video Liked!'),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      Icons.share,
                      'Share',
                      () => print('Share clicked!'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 28),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
