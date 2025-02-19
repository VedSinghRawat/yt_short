import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:video_player/video_player.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';

class SpeechExerciseScreen extends StatefulWidget {
  final SpeechExercise exercise;
  final Function(VideoPlayerController)? onControllerInitialized;
  final bool isVisible;

  const SpeechExerciseScreen({
    super.key,
    this.onControllerInitialized,
    required this.exercise,
    this.isVisible = false,
  });

  @override
  State<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends State<SpeechExerciseScreen> {
  late VideoPlayerController? _controller;
  bool _hasShownDialog = false;

  late void Function() _pauseListener;
  void _onControllerInitialized(VideoPlayerController controller) {
    _pauseListener = () {
      if (!_hasShownDialog &&
          controller.value.position.inSeconds >= widget.exercise.pauseAt &&
          controller.value.isPlaying) {
        controller.pause();
        _showTestSentenceDialog();
      }
    };
    _controller = controller;

    controller.addListener(_pauseListener);
  }

  void _showTestSentenceDialog() {
    setState(() {
      _hasShownDialog = true;
    });
    _controller!.removeListener(_pauseListener);

    showDialog(
      context: context,
      barrierDismissible: kDebugMode,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.8),
      builder: (context) => PopScope(
        canPop: kDebugMode,
        child: Dialog(
          backgroundColor: const Color.fromRGBO(255, 255, 255, 0.75),
          insetPadding: const EdgeInsets.symmetric(
            vertical: 48,
            horizontal: 24,
          ),
          child: ExerciseSentenceCard(
            text: widget.exercise.text,
            onContinue: () {
              setState(() {
                _controller?.play();
              });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YtPlayer(
      key: Key('${widget.exercise.level}-${widget.exercise.subLevel}-${widget.exercise.ytId}'),
      ytVidId: widget.exercise.ytId,
      isVisible: widget.isVisible,
      onControllerInitialized: _onControllerInitialized,
    );
  }
}
