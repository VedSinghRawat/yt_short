import 'package:flutter/material.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
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
  bool _isCheckingPauseTime = false;

  void _onControllerInitialized(YoutubePlayerController controller) {
    if (_isDisposed) return;

    _controller = controller;

    // Set up controller listener for player state changes
    controller.listen((event) {
      if (_isDisposed || !mounted) return;

      // Only check for pause time when the video is playing
      if (!_hasShownDialog && event.playerState == PlayerState.playing) {
        _checkVideoPauseTime();
      }
    });
  }

  // Check current video position to determine if we should pause
  Future<void> _checkVideoPauseTime() async {
    if (_isDisposed || !mounted || _hasShownDialog || _isCheckingPauseTime) return;

    // Prevent multiple simultaneous checks
    _isCheckingPauseTime = true;

    try {
      // Get the current video time in seconds
      final position = await _controller!.currentTime;

      // Check if we've reached the pause point
      if (position >= widget.exercise.pauseAt) {
        _controller!.pauseVideo();
        _hasShownDialog = true;
        _showExerciseDialog();
      }
    } catch (e) {
      // Silently handle any errors
    } finally {
      _isCheckingPauseTime = false;
    }
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
              _controller?.playVideo();
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
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
