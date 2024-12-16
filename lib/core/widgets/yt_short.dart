import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeShort extends StatefulWidget {
  final String videoId;

  const YoutubeShort({super.key, required this.videoId});

  @override
  State<YoutubeShort> createState() => _YoutubeShortState();
}

class _YoutubeShortState extends State<YoutubeShort> {
  YoutubePlayerController? _controller;
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer(); // Initialize player immediately
  }

  void _initializePlayer() {
    if (!_isPlayerInitialized) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          hideControls: false,
        ),
      );
      _isPlayerInitialized = true;
      print("Player controller initialized: $_isPlayerInitialized");
    }
  }

  @override
  void deactivate() {
    _controller?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building YoutubePlayer widget");

    // VisibilityDetector logic (commented out for now)
    // VisibilityDetector(
    //   key: Key(widget.videoId),
    //   onVisibilityChanged: (VisibilityInfo info) {
    //     print("Visibility changed for ${widget.videoId}: visibleFraction: ${info.visibleFraction}");
    //     // ... (previous visibility logic) ...
    //   },

    return _controller != null
        ? YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.blueAccent,
            aspectRatio: 9 / 16, // Standard YouTube Shorts aspect ratio
          )
        : const SizedBox();
  }
}
