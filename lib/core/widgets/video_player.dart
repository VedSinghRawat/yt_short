import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:video_player/video_player.dart';

class MediaPlayer extends ConsumerStatefulWidget {
  final String mediaPath;
  final void Function(VideoPlayerController)? onControllerCreated;
  final VoidCallback onError;
  final bool shouldInitialize;

  const MediaPlayer({
    super.key,
    required this.onError,
    required this.shouldInitialize,
    required this.mediaPath,
    this.onControllerCreated,
  });

  @override
  ConsumerState<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends ConsumerState<MediaPlayer> {
  VideoPlayerController? _mediaPlayerController;
  bool _hasInitialized = false;

  Future<void> _initVideoPlayer() async {
    if (_mediaPlayerController != null || _hasInitialized) return;

    Console.log('reinitialize');

    _mediaPlayerController = VideoPlayerController.file(
      File(widget.mediaPath),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: true,
      ),
    )..setLooping(true);

    try {
      await _mediaPlayerController!.initialize();
      _hasInitialized = true;
      widget.onControllerCreated?.call(_mediaPlayerController!);
    } catch (e) {
      Console.error(
        Failure(message: 'error during video player initialize $e'),
        StackTrace.current,
      );

      widget.onError();
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.shouldInitialize) {
      _initVideoPlayer();
    }
  }

  @override
  void didUpdateWidget(covariant MediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.shouldInitialize && widget.shouldInitialize) {
      if (_mediaPlayerController == null || !_hasInitialized) {
        _initVideoPlayer();
      }
    } else if (oldWidget.shouldInitialize && !widget.shouldInitialize) {
      _mediaPlayerController?.dispose();
      setState(() {
        _mediaPlayerController = null;
        _hasInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _mediaPlayerController?.dispose();
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
