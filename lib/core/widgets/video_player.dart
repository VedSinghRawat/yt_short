import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;

// Stateful widget to fetch and then display video sublevel.
class MediaPlayer extends StatefulWidget {
  final String mediaUrl;
  final void Function(VideoPlayerController)? onControllerCreated;

  const MediaPlayer({
    super.key,
    required this.mediaUrl,
    this.onControllerCreated,
  });

  @override
  State<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  VideoPlayerController? _mediaPlayerController;

  _initVideoPlayer() async {
    _mediaPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.mediaUrl),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: true,
      ),
    );

    _mediaPlayerController!.setLooping(true);

    await _mediaPlayerController!.initialize();

    // Notify parent when controller is created
    developer.log('controller created');
    widget.onControllerCreated?.call(_mediaPlayerController!);
  }

  @override
  void initState() {
    super.initState();

    _initVideoPlayer();
  }

  @override
  Future<void> dispose() async {
    if (_mediaPlayerController != null) {
      _mediaPlayerController!.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _mediaPlayerController?.value.isInitialized == true
        ? Stack(
            children: [
              if (_mediaPlayerController!.value.isBuffering) const Loader(),
              VideoPlayer(_mediaPlayerController!),
            ],
          )
        : const Loader();
  }
}
