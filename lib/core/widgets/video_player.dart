import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as video_player;
import 'package:chewie/chewie.dart';

/// Stateful widget to fetch and then display video content.
class VideoPlayer extends StatefulWidget {
  final String videoUrl;
  const VideoPlayer({super.key, required this.videoUrl});

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late video_player.VideoPlayerController _videoPlayerController;
  ChewieController? _controller;

  void _initVideoPlayer() async {
    _videoPlayerController =
        video_player.VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    await _videoPlayerController.initialize();

    final chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: true,
      showControls: false,
      aspectRatio: 9 / 16,
      allowFullScreen: false,
      draggableProgressBar: false,
    );

    setState(() {
      _controller = chewieController;
    });
  }

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null
        ? const Center(child: CircularProgressIndicator())
        : Chewie(controller: _controller!);
  }
}
