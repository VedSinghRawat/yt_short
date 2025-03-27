import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';

class Player extends ConsumerStatefulWidget {
  final String videoPath;
  final String? uniqueId;
  final Function(BetterPlayerController controller)? onControllerInitialized;

  const Player({
    super.key,
    required this.videoPath,
    this.onControllerInitialized,
    this.uniqueId,
  });

  @override
  ConsumerState<Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<Player> {
  BetterPlayerController? _betterPlayerController;

  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;

  String? error;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    _betterPlayerController = _initializeBetterPlayerController();
  }

  void _listenerVideoFinished() async {
    if (_betterPlayerController == null) return;

    final position = await _betterPlayerController!.videoPlayerController?.position;
    final duration = _betterPlayerController!.videoPlayerController?.value.duration;

    if (position != null && duration != null) {
      final compareDuration = duration.inSeconds - position.inSeconds;

      if (duration != Duration.zero &&
          compareDuration <= 1 &&
          !ref.read(sublevelControllerProvider).hasFinishedVideo) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
        _betterPlayerController?.removeEventsListener(_eventListener);
      }
    }
  }

  void _eventListener(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      _listenerVideoFinished();
    }
  }

  void _changePlayingState({bool changeToPlay = true}) async {
    if (_betterPlayerController == null) return;

    final isPlaying = _betterPlayerController!.isPlaying();

    if (isPlaying == true || !changeToPlay) {
      _betterPlayerController!.pause();
    } else {
      _betterPlayerController!.play();
    }

    setState(() {
      _iconData = isPlaying == false ? Icons.play_arrow : Icons.pause;
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

  void _handleVisibility(bool isVisible) {
    _isVisible = isVisible;

    if (_betterPlayerController == null) return;

    if (isVisible) {
      _betterPlayerController?.addEventsListener(_eventListener);
      _betterPlayerController?.play();
    } else {
      _betterPlayerController?.removeEventsListener(_eventListener);
      _betterPlayerController?.pause();
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isVisible =
        info.visibleFraction > 0.8 || (_isVisible == true && info.visibleFraction > 0.3);

    if (_isVisible == isVisible) return;

    try {
      setState(() {
        _isVisible = isVisible;
      });

      if (isVisible && error != null) {
        ref.read(sublevelControllerProvider.notifier).setHasFinishedVideo(true);
      }

      _handleVisibility(isVisible);
    } catch (e) {
      developer.log('Error in Player._onVisibilityChanged', error: e.toString());
    }
  }

  BetterPlayerController _initializeBetterPlayerController() {
    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: false,
        looping: true,
        fit: BoxFit.fitHeight,
        aspectRatio: 9 / 16,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
    );
    controller
        .setupDataSource(BetterPlayerDataSource(BetterPlayerDataSourceType.file, widget.videoPath));

    widget.onControllerInitialized?.call(controller);
    return controller;
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
            if (error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ErrorPage(
                    text: error!,
                  ),
                ),
              )
            else
              Builder(
                builder: (_) {
                  if (_betterPlayerController == null && _isVisible) {}
                  return _betterPlayerController != null
                      ? SizedBox(
                          height: MediaQuery.of(context).size.height,
                          child: BetterPlayer(
                            controller: _betterPlayerController!,
                          ))
                      : const Center(child: CircularProgressIndicator());
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
