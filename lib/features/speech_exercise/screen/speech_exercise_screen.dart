import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/player_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/user/user_controller.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final Function(VideoPlayerController)? onControllerInitialized;
  final String? uniqueId;
  final String videoPath;

  const SpeechExerciseScreen({
    super.key,
    this.onControllerInitialized,
    required this.exercise,
    required this.videoPath,
    this.uniqueId,
  });

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  VideoPlayerController? _controller;
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

    setState(() {
      _controller = controller;
    });

    _controller?.addListener(_pauseListener);
  }

  void _showTestSentenceDialog() {
    setState(() {
      _hasShownDialog = true;
    });
    _controller?.removeListener(_pauseListener);

    final isAdmin = ref.read(userControllerProvider).currentUser?.isAdmin ?? false;

    showDialog(
      context: context,
      barrierDismissible: isAdmin || kDebugMode,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.9),
      builder: (context) => PopScope(
        canPop: isAdmin || kDebugMode,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            vertical: 48,
            horizontal: 24,
          ),
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
                setState(() {
                  _controller?.play();
                });
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
      key: Key(widget.uniqueId ?? widget.videoPath),
      videoPath: widget.videoPath,
      uniqueId: widget.uniqueId,
      onControllerInitialized: _onControllerInitialized,
    );
  }
}
