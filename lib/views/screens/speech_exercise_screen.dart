import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/views/widgets/speech_exercise/exercise_sentence_card.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final VoidCallback goToNext;

  const SpeechExerciseScreen({super.key, required this.exercise, required this.goToNext});

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  @override
  Widget build(BuildContext context) {
    return SpeechExerciseCard(
      key: UniqueKey(),
      levelId: widget.exercise.levelId,
      audioFilename: widget.exercise.id,
      text: widget.exercise.text,
      onContinue: widget.goToNext,
    );
  }
}
