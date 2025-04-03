import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/video_player.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final Function(BetterPlayerController controller)? onControllerInitialized;
  final String? uniqueId;
  final String? videoLocalPath;
  final String? videoUrl;

  const SpeechExerciseScreen({
    super.key,
    this.onControllerInitialized,
    required this.exercise,
    this.videoLocalPath,
    this.videoUrl,
    this.uniqueId,
  });

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  BetterPlayerController? _controller;
  bool _hasShownDialog = false;

  void _onControllerInitialized(BetterPlayerController controller) {
    _controller = controller;

    _controller?.addEventsListener((event) {
      if (_hasShownDialog || event.betterPlayerEventType != BetterPlayerEventType.progress) return;

      final position = _controller?.videoPlayerController?.value.position;
      final isPlaying = _controller?.videoPlayerController?.value.isPlaying ?? false;

      if (position != null && isPlaying && position.inSeconds >= widget.exercise.pauseAt) {
        _controller?.pause();
        _showTestSentenceDialog();
      }
    });

    widget.onControllerInitialized?.call(controller);
  }

  void _showTestSentenceDialog() {
    setState(() {
      _hasShownDialog = true;
    });

    final isAdmin = ref.read(userControllerProvider).currentUser?.isAdmin ?? false;

    showDialog(
      context: context,
      barrierDismissible: isAdmin || kDebugMode,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.9),
      builder: (context) => PopScope(
        canPop: isAdmin || kDebugMode,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.75),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(255, 255, 255, 0.2),
                  blurRadius: 12.0,
                  spreadRadius: 4.0,
                ),
              ],
            ),
            child: SpeechExerciseCard(
              text: widget.exercise.text,
              onContinue: () {
                _controller?.play();
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Player(
      key: Key(widget.uniqueId ?? widget.videoLocalPath ?? widget.videoUrl ?? ''),
      videoLocalPath: widget.videoLocalPath,
      videoUrl: widget.videoUrl,
      uniqueId: widget.uniqueId,
      onControllerInitialized: _onControllerInitialized,
    );
  }
}
