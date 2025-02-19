import 'dart:async';
import 'dart:developer' as developer;
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
    if (!mounted || _videoController == null || _audioController == null) return;

    if (state == AppLifecycleState.resumed) {
      _videoController!.play();
      _audioController!.play();
    } else if (state == AppLifecycleState.paused) {
      _videoController!.pause();
      _audioController!.pause();
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

  void _togglePlayPause() {
    if (_videoController == null || _audioController == null) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _audioController!.pause();
      } else {
        _videoController!.play();
        _audioController!.play();
      }

      _iconData = _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow;
      _showPlayPauseIcon = true;
    });

    // Hide the icon after 2 seconds
    _iconTimer?.cancel();
    _iconTimer = Timer(Duration(seconds: _iconData == Icons.play_arrow ? 1 : 2), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant YtPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible &&
        _videoController != null &&
        _audioController != null) {
      if (widget.isVisible) {
        _videoController!.addListener(_listenerVideoFinished);
        _videoController!.play();
        _audioController!.play();
      } else {
        _videoController!.removeListener(_listenerVideoFinished);
        _videoController!.pause();
        _audioController!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vidUrl == null || _audioUrl == null) return const Loader();
    developer.log(
        'build YtPlayer ${widget.key.toString()}, init: ${_videoController?.value.isInitialized ?? _audioController?.value.isInitialized}, visible: ${widget.isVisible}');

    return GestureDetector(
      onTap: _togglePlayPause,
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
                  widget.onControllerInitialized?.call(controller);
                  if (_videoController == null || _audioController == null) return;

                  if (widget.isVisible) {
                    _videoController!.play();
                    _audioController!.play();
                  } else {
                    _videoController!.pause();
                    _audioController!.pause();
                  }
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
