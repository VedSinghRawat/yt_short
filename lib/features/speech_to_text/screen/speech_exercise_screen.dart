import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/core/widgets/yt_player.dart';

class SpeechExerciseScreen extends StatefulWidget {
  final SpeechExercise exercise;

  const SpeechExerciseScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends State<SpeechExerciseScreen> {
  void _onControllerInitialized(YoutubePlayerController controller) {
    // Listen to video progress and pause at specified time
    controller.addListener(() {
      if (controller.value.position.inSeconds >= widget.exercise.pauseAt && controller.value.isPlaying) {
        controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            YtPlayer(
              videoId: widget.exercise.ytId,
              onControllerInitialized: _onControllerInitialized,
            ),
          ],
        ),
      ),
    );
  }
}
