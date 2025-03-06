import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/features/speech_exercise/widgets/exercise_sentence_card.dart';

class SpeechExerciseScreen extends StatefulWidget {
  final SpeechExercise exercise;
  final Function(YoutubePlayerController)? onControllerInitialized;
  final String? uniqueId;

  const SpeechExerciseScreen({
    super.key,
    this.onControllerInitialized,
    required this.exercise,
    this.uniqueId,
  });

  @override
  State<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends State<SpeechExerciseScreen> {
  YoutubePlayerController? _controller;
  bool _hasShownDialog = false;
  bool _isDisposed = false;

  late void Function() _pauseListener;

  void _onControllerInitialized(YoutubePlayerController controller) {
    if (_isDisposed) return;

    _controller = controller;
    _pauseListener = () {
      if (_isDisposed) return;

      if (!_hasShownDialog &&
          _controller!.value.position.inSeconds >= widget.exercise.pauseAt &&
          _controller!.value.isPlaying) {
        _controller!.pause();
        _hasShownDialog = true;
        _showExerciseDialog();
      }
    };

    controller.addListener(_pauseListener);
  }

  Future<void> _showExerciseDialog() async {
    if (_isDisposed || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.exercise.text),
          content: ExerciseSentenceCard(
            onContinue: () {
              if (_isDisposed) return;
              Navigator.of(context).pop();
              _controller?.play();
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_controller != null) {
      _controller!.removeListener(_pauseListener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YtPlayer(
      key: Key('${widget.exercise.level}-${widget.exercise.subLevel}-${widget.exercise.ytId}'),
      videoId: widget.exercise.ytId,
      uniqueId: widget.uniqueId,
      onControllerInitialized: _onControllerInitialized,
    );
  }
}
