import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/youtube_service.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/core/widgets/video_player.dart';
import 'package:myapp/features/content/content_controller.dart';
import 'package:video_player/video_player.dart';

class YtPlayer extends ConsumerStatefulWidget {
  final String ytVidId;
  final bool isVisible;
  final void Function(VideoPlayerController controller)? onControllerInitialized;

  const YtPlayer({
    super.key,
    required this.ytVidId,
    this.onControllerInitialized,
    this.isVisible = false,
  });

  @override
  ConsumerState<YtPlayer> createState() => _YtPlayerState();
}

class _YtPlayerState extends ConsumerState<YtPlayer> with WidgetsBindingObserver {
  String? _vidUrl;
  String? _audioUrl;
  VideoPlayerController? _videoController;
  VideoPlayerController? _audioController;
  bool _showPlayPauseIcon = false;
  IconData _iconData = Icons.play_arrow;
  Timer? _iconTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final data = await ref.read(youtubeServiceProvider).getVideoMp4Url(widget.ytVidId);

      if (!mounted) return;
      setState(() {
        _vidUrl = data['video'].toString();
        _audioUrl = data['audio'].toString();
      });
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iconTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_isControllerInitialized) return;

    if (state == AppLifecycleState.resumed) {
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
      _iconData = _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow;

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

  @override
  void didUpdateWidget(covariant YtPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible == oldWidget.isVisible || !_isControllerInitialized) {
      return;
    }

    _handleListener();
  }

  void _handleListener() {
    if (_videoController == null) return;

    widget.isVisible
        ? _videoController!.addListener(_listenerVideoFinished)
        : _videoController!.removeListener(_listenerVideoFinished);

    _changePlaying(widget.isVisible);
  }

  @override
  Widget build(BuildContext context) {
    if (_vidUrl == null || _audioUrl == null) return const Loader();

    return GestureDetector(
      onTap: _changePlayingState,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Stack(
            children: [
              MediaPlayer(
                mediaUrl: _audioUrl!,
                onControllerCreated: (controller) {
                  setState(() {
                    _audioController = controller;
                  });
                },
              ),
              MediaPlayer(
                mediaUrl: _vidUrl!,
                onControllerCreated: (controller) {
                  setState(() {
                    _videoController = controller;
                  });

                  _handleListener();

                  widget.onControllerInitialized?.call(controller);
                },
              ),
            ],
          ),
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
        ],
      ),
    );
  }
}
