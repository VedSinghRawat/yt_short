import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/content/content_controller.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'dart:developer' as developer;

class YtShortPlayer extends ConsumerStatefulWidget {
  final String videoId;
  final String? uniqueId;
  final void Function(YoutubePlayerController controller)? onControllerInitialized;

  const YtShortPlayer({
    super.key,
    required this.videoId,
    this.onControllerInitialized,
    this.uniqueId,
  });

  @override
  ConsumerState<YtShortPlayer> createState() => _YtShortPlayerState();
}

class _YtShortPlayerState extends ConsumerState<YtShortPlayer> {
  late YoutubePlayerController _controller;
  bool _isVisible = false;
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

  void _listenerVideoFinished() {
    final videoDuration = _controller.value.metaData.duration;

    final compareDuration = videoDuration.inSeconds - _controller.value.position.inSeconds;
    if (_controller.value.hasPlayed &&
        videoDuration != Duration.zero &&
        compareDuration <= 1 &&
        !ref.read(contentControllerProvider).hasFinishedVideo) {
      ref.read(contentControllerProvider.notifier).setHasFinishedVideo(true);
      _controller.removeListener(_listenerVideoFinished);
    }
  }

  void changeListenerAsVisibility() {
    _isVisible
        ? _controller.addListener(_listenerVideoFinished)
        : _controller.removeListener(_listenerVideoFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      !_controller.value.isPlaying ? _controller.play() : _controller.pause();
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
        _isVisible = info.visibleFraction > 0.6;
        _isVisible ? _controller.play() : _controller.pause();
      });

      changeListenerAsVisibility();
    } catch (e) {
      developer.log('Error in YtShortPlayer._onVisibilityChanged', error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoId),
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
                  if (_controller.value.isPlaying && !_isVisible) return;

                  _controller.play();
                  changeListenerAsVisibility();
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
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
