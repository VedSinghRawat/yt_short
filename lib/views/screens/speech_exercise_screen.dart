import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/views/widgets/speech_exercise/exercise_sentence_card.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final VoidCallback goToNext;
  final bool isVisible;

  const SpeechExerciseScreen({super.key, required this.exercise, required this.goToNext, required this.isVisible});

  @override
  ConsumerState<SpeechExerciseScreen> createState() => _SpeechExerciseScreenState();
}

class _SpeechExerciseScreenState extends ConsumerState<SpeechExerciseScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(SpeechExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if isVisible changed from true to false (user scrolled away)
    if (oldWidget.isVisible && !widget.isVisible) {
      // Clear speech controller state when user scrolls away
      // Delay the modification to avoid modifying provider during widget lifecycle
      Future(() {
        ref.read(speechProvider.notifier).clearState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          child: SpeechExerciseCard(
            key: UniqueKey(),
            levelId: widget.exercise.levelId,
            id: widget.exercise.id,
            text: widget.exercise.text,
            onContinue: widget.goToNext,
          ),
        ),
      ),
    );
  }
}
