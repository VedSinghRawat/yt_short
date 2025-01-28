import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YtShortPlayer extends StatefulWidget {
  final String videoId;
  final void Function(YoutubePlayerController controller)? onControllerInitialized;

  const YtShortPlayer({
    super.key,
    required this.videoId,
    this.onControllerInitialized,
  });

  @override
  State<YtShortPlayer> createState() => _YtShortPlayerState();
}

class _YtShortPlayerState extends State<YtShortPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: false,
        enableCaption: false,
        controlsVisibleAtStart: false,
        loop: true,
      ),
    );
    widget.onControllerInitialized?.call(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
          aspectRatio: 9 / 16,
        ),
      ),
    );
  }
}
