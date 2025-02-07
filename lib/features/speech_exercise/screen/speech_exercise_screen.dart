import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/core/widgets/yt_short_player.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';

class SpeechExerciseScreen extends StatefulWidget {
  final SpeechExercise exercise;
  final Function(YoutubePlayerController) onControllerInitialized;

  const SpeechExerciseScreen({
    super.key,
    required this.onControllerInitialized,
    required this.exercise,
  });

  @override
  State<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends State<SpeechExerciseScreen> {
  late YoutubePlayerController? _controller;
  bool _hasShownDialog = false;

  void _onControllerInitialized(YoutubePlayerController controller) {
    _controller = controller;

    controller.addListener(() {
      if (!_hasShownDialog &&
          controller.value.position.inSeconds >= widget.exercise.pauseAt &&
          controller.value.isPlaying) {
        controller.pause();
        _showTestSentenceDialog();
      }
    });

    widget.onControllerInitialized(controller);
  }

  void _showTestSentenceDialog() {
    _hasShownDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.8),
      builder: (context) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: const Color.fromRGBO(255, 255, 255, 0.75),
            insetPadding: const EdgeInsets.symmetric(
              vertical: 48,
              horizontal: 24,
            ),
            child: ExerciseSentenceCard(
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
    return YtShortPlayer(
      videoId: widget.exercise.ytId,
      onControllerInitialized: _onControllerInitialized,
    );
  }
}
