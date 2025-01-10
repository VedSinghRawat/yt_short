import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/core/widgets/yt_player.dart';
import 'package:myapp/features/speech_to_text/widgets/test_sentence_card.dart';

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
  late YoutubePlayerController? _controller;
  bool _hasShownDialog = false;

  void _onControllerInitialized(YoutubePlayerController controller) {
    _controller = controller;

    controller.addListener(() {
      if (!_hasShownDialog && controller.value.position.inSeconds >= widget.exercise.pauseAt && controller.value.isPlaying) {
        controller.pause();
        _showTestSentenceDialog();
      }
    });
  }

  void _showTestSentenceDialog() {
    _hasShownDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.white.withOpacity(0.15),
            insetPadding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.15,
              horizontal: 24,
            ),
            child: TestSentenceCard(
              text: widget.exercise.textToSpeak,
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
    return Scaffold(
      body: SafeArea(
        child: YtPlayer(
          videoId: widget.exercise.ytId,
          onControllerInitialized: _onControllerInitialized,
        ),
      ),
    );
  }
}
