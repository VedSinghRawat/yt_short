import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:developer' as developer;

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
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        mute: false,
        hideControls: false,
        enableCaption: false,
        controlsVisibleAtStart: false,
        loop: true,
        autoPlay: false,
      ),
    );
    widget.onControllerInitialized?.call(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    try {
      if (info.visibleFraction > 0.8 && !_isVisible) {
        _isVisible = true;
        _controller.play();
      } else if (info.visibleFraction <= 0.8 && _isVisible) {
        _isVisible = false;
        _controller.pause();
      }
    } catch (e) {
      developer.log('Error in YtShortPlayer._onVisibilityChanged', error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoId),
      onVisibilityChanged: _onVisibilityChanged,
      child: AspectRatio(
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
      ),
    );
  }
}
