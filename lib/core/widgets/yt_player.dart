import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/video_player.dart';
import 'package:myapp/features/content/content_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class YtPlayer extends ConsumerStatefulWidget {
  final String audioUrl;
  final String videoUrl;
  final String? uniqueId;
  final void Function(VideoPlayerController controller, VideoPlayerController audioController)?
      onControllerInitialized;

  const YtPlayer({
    super.key,
    required this.audioUrl,
    required this.videoUrl,
    this.uniqueId,
    this.onControllerInitialized,
  });

  @override
  ConsumerState<YtPlayer> createState() => _YtPlayerState();
}

class _YtPlayerState extends ConsumerState<YtPlayer>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  VideoPlayerController? _audioController;
  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;
  bool _isVisible = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iconTimer?.cancel();
    super.dispose();
  }

  // stop and start video when app close or start
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_isControllerInitialized) return;

    // start only current video
    if (state == AppLifecycleState.resumed && _isVisible) {
      _changePlayingState(changeToPlay: true);

      return;
    }

    if (state == AppLifecycleState.paused) {
      _changePlayingState(changeToPlay: false);
    }
  }

  void _listenerVideoFinished() {
    if (_videoController == null) return;

    final videoDuration = _videoController!.value.duration;
    final position = _videoController!.value.position;
    final compareDuration = videoDuration.inSeconds - position.inSeconds;

    if (videoDuration != Duration.zero &&
        compareDuration <= 1 &&
        !ref.read(contentControllerProvider).hasFinishedVideo) {
      ref.read(contentControllerProvider.notifier).setHasFinishedVideo(true);
      _videoController!.removeListener(_listenerVideoFinished);
    }
  }

  void _changePlayingState({bool changeToPlay = true}) {
    if (!_isControllerInitialized) return;

    _changePlaying(changeToPlay);

    setState(() {
      _iconData = !_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow;

      _showPlayPauseIcon = true;
    });

    _iconTimer?.cancel();

    _iconTimer = Timer(Duration(milliseconds: _iconData == Icons.play_arrow ? 700 : 2000), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  bool get _isControllerInitialized => _videoController != null && _audioController != null;

  void _changePlaying(bool changeToPlay) {
    if (!_isControllerInitialized) return;

    if (_videoController!.value.isPlaying || !changeToPlay) {
      _videoController!.pause();
      _audioController!.pause();
    } else {
      _videoController!.play();
      _audioController!.play();
    }
  }

  void _handleListener() {
    if (_videoController == null) return;

    _isVisible
        ? _videoController!.addListener(_listenerVideoFinished)
        : _videoController!.removeListener(_listenerVideoFinished);

    _changePlaying(_isVisible);
  }

  // need because when we navigate to another route this will stop video
  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isVisible = info.visibleFraction > 0.6;

    if (_isVisible == isVisible) return;

    try {
      developer.log('VisibilityInfo: ${info.visibleFraction} $isVisible, $_isVisible');
      setState(() {
        _isVisible = isVisible;
      });

      _handleListener();
    } catch (e) {
      developer.log('Error in YtShortPlayer._onVisibilityChanged', error: e.toString());
    }
  }

  void _onControllerInitialized(
      VideoPlayerController? videoController, VideoPlayerController? audioController) {
    if (videoController == null || audioController == null) return;

    _handleListener();
    widget.onControllerInitialized?.call(videoController, audioController);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.audioUrl),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _changePlayingState,
        child: Stack(
          alignment: Alignment.center,
          children: [
            MediaPlayer(
              mediaUrl: widget.audioUrl,
              onControllerCreated: (controller) {
                if (_audioController != controller) {
                  setState(() {
                    _audioController = controller;
                  });

                  _onControllerInitialized(_videoController, controller);
                }
              },
            ),
            MediaPlayer(
              mediaUrl: widget.videoUrl,
              onControllerCreated: (controller) {
                if (_videoController != controller) {
                  setState(() {
                    _videoController = controller;
                  });
                  _onControllerInitialized(controller, _audioController);
                }
              },
            ),
            PlayPauseButton(showPlayPauseIcon: _showPlayPauseIcon, iconData: _iconData),
          ],
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
          size: MediaQuery.of(context).size.width * 0.1,
          color: Colors.white,
        ),
      ),
    );
  }
}
