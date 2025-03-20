import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';
import 'package:video_player/video_player.dart';

// Stateful widget to fetch and then display video sublevel.
class MediaPlayer extends ConsumerStatefulWidget {
  final String mediaPath;
  final void Function(VideoPlayerController)? onControllerCreated;
  final VoidCallback onError;

  const MediaPlayer({
    super.key,
    required this.onError,
    required this.mediaPath,
    this.onControllerCreated,
  });

  @override
  ConsumerState<MediaPlayer> createState() => _MediaPlayerState();
}

class _MediaPlayerState extends ConsumerState<MediaPlayer> {
  VideoPlayerController? _mediaPlayerController;

  _initVideoPlayer() async {
    _mediaPlayerController = VideoPlayerController.file(
      File(widget.mediaPath),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: true,
      ),
    );

    _mediaPlayerController!.setLooping(true);

    try {
      await _mediaPlayerController!.initialize();
      // Notify parent when controller is created
      widget.onControllerCreated?.call(_mediaPlayerController!);
    } catch (e) {
      Console.error(Failure(message: 'error during video player initialize $e'));

      widget.onError();
    }
  }

  @override
  void initState() {
    super.initState();

    _initVideoPlayer();
  }

  @override
  Future<void> dispose() async {
    if (_mediaPlayerController != null) {
      _mediaPlayerController!.dispose();
    }

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
