import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/video_player.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Player extends ConsumerStatefulWidget {
  final String videoPath;
  final String? uniqueId;

  final void Function(VideoPlayerController controller)? onControllerInitialized;

  const Player({
    super.key,
    required this.videoPath,
    this.uniqueId,
    this.onControllerInitialized,
  });

  @override
  ConsumerState<Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<Player> {
  VideoPlayerController? _videoController;

  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;

  String? error;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
  }

  void _listenerVideoFinished() {
    if (_videoController == null) return;

    final videoDuration = _videoController!.value.duration;
    final position = _videoController!.value.position;
    final compareDuration = videoDuration.inSeconds - position.inSeconds;

    if (videoDuration != Duration.zero &&
        compareDuration <= 1 &&
        !ref.read(sublevelControllerProvider).hasFinishedVideo) {
      ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
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

  bool get _isControllerInitialized => _videoController != null;

  void _changePlaying(bool changeToPlay) {
    if (!_isControllerInitialized) return;

    if (_videoController!.value.isPlaying || !changeToPlay) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  void _handleListener() {
    if (_videoController == null) return;

    _isVisible
        ? _videoController!.addListener(_listenerVideoFinished)
        : _videoController!.removeListener(_listenerVideoFinished);

    _changePlaying(_isVisible);
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isVisible = info.visibleFraction > 0.6;

    if (_isVisible == isVisible) return;

    try {
      setState(() {
        _isVisible = isVisible;
      });

      if (isVisible && error != null) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
      }

      _handleListener();
    } catch (e) {
      developer.log('Error in Player._onVisibilityChanged', error: e.toString());
    }
  }

  void _onControllerInitialized(VideoPlayerController controller) {
    setState(() {
      if (_videoController != controller) {
        _videoController = controller;
      }
    });

    _handleListener();

    widget.onControllerInitialized?.call(controller);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueId ?? widget.videoPath),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _changePlayingState,
        child: Stack(
          alignment: Alignment.center,
          children: [
            error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ErrorPage(
                        text: error!,
                      ),
                    ),
                  )
                : MediaPlayer(
                    mediaPath: widget.videoPath,
                    onControllerCreated: _onControllerInitialized,
                    onError: () {
                      setState(() {
                        error =
                            'For some reason, we are unable to play this video right now. You can skip it for now.';
                      });
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
          size: MediaQuery.of(context).size.width * 0.12,
          color: Colors.white,
        ),
      ),
    );
  }
}
