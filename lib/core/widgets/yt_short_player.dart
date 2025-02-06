import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
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
  bool _playVid = false;
  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        mute: false,
        hideControls: true,
        enableCaption: false,
        showLiveFullscreenButton: false,
        disableDragSeek: true,
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
    _iconTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _playVid = !_controller.value.isPlaying;
      _iconData = _controller.value.isPlaying ? Icons.pause : Icons.play_arrow;

      _showPlayPauseIcon = true;
    });

    // Hide the icon after 2 seconds
    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(seconds: _iconData == Icons.play_arrow ? 1 : 2), () {
      setState(() {
        _showPlayPauseIcon = false;
      });
    });
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    try {
      setState(() {
        if (info.visibleFraction > 0.8 && !_playVid) {
          _playVid = true;
        } else if (info.visibleFraction <= 0.8 && _playVid) {
          _playVid = false;
        }
      });
    } catch (e) {
      developer.log('Error in YtShortPlayer._onVisibilityChanged', error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    _playVid ? _controller.play() : _controller.pause();

    return VisibilityDetector(
      key: Key(widget.videoId),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: YoutubePlayer(
                controller: _controller,
                onReady: () {
                  _playVid ? _controller.play() : _controller.pause();
                },
              ),
            ),
            // Play/Pause Icon (shows for 2 seconds)
            AnimatedOpacity(
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
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            ValueListenableBuilder<YoutubePlayerValue>(
              valueListenable: _controller,
              builder: (context, value, child) {
                if (!value.hasPlayed &&
                    value.metaData.duration == Duration.zero &&
                    value.buffered == 0.0) {
                  return const Loader();
                }
                if (!_playVid) {
                  setState(() {
                    _playVid = true;
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
