import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/widgets/video_player.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:video_player/video_player.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final String? uniqueId;
  final String? videoLocalPath;
  final String? videoUrl;

  const SpeechExerciseScreen({
    super.key,
    required this.exercise,
    this.videoLocalPath,
    this.videoUrl,
    this.uniqueId,
  });

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  VideoPlayerController? _exerciseController;
  bool _hasShownDialog = false;

  void _onControllerInitialized(VideoPlayerController controller) {
    if (!mounted) return;

    _exerciseController?.removeListener(_exerciseListener);

    setState(() {
      _exerciseController = controller;
    });
    _exerciseController!.addListener(_exerciseListener);
  }

  void _exerciseListener() {
    if (!mounted || _exerciseController == null || !_exerciseController!.value.isInitialized) {
      return;
    }

    final position = _exerciseController!.value.position;
    final isPlaying = _exerciseController!.value.isPlaying;

    if (!_hasShownDialog && isPlaying && position.inSeconds >= widget.exercise.pauseAt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasShownDialog) {
          _showTestSentenceDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _exerciseController?.removeListener(_exerciseListener);
    super.dispose();
  }

  void _showTestSentenceDialog() {
    _exerciseController?.pause();

    if (!mounted) return;

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
                if (mounted) {
                  _exerciseController?.play();
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(
      key: Key(widget.uniqueId ?? widget.videoLocalPath ?? widget.videoUrl ?? ''),
      videoLocalPath: widget.videoLocalPath,
      videoUrl: widget.videoUrl,
      uniqueId: widget.uniqueId,
      onControllerInitialized: _onControllerInitialized,
      dialogues: widget.exercise.dialogues,
    );
  }
}
