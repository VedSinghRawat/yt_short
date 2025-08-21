import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/views/widgets/exercise_container.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/views/widgets/speech_exercise/exercise_sentence_card.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/controllers/speech/speech_controller.dart';

class SpeechExerciseScreen extends ConsumerStatefulWidget {
  final SpeechExercise exercise;
  final VoidCallback goToNext;
  final bool isCurrent;

  const SpeechExerciseScreen({super.key, required this.exercise, required this.goToNext, required this.isCurrent});

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

    if (oldWidget.isCurrent && !widget.isCurrent) {
      Future(() {
        if (mounted) {
          ref.read(speechProvider(targetWords: widget.exercise.text.split(' ')).notifier).resetState();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseContainer(
      titleHindi: 'स्पीच एक्सरसाइज़',
      titleHinglish: 'Speech Exercise',
      descriptionHindi: 'नीचे दिया गया वाक्य सही उच्चारण के साथ बोलें।',
      descriptionHinglish: 'Niche diya gaya vakya sahi ucharan ke saath bole.',
      exerciseType: SubLevelType.speech,
      child: ConstrainedBox(
        constraints:
            MediaQuery.of(context).orientation == Orientation.landscape
                ? const BoxConstraints(maxWidth: 600)
                : const BoxConstraints(maxWidth: 99999),
        child: SpeechExerciseCard(
          key: UniqueKey(),
          levelId: widget.exercise.levelId,
          id: widget.exercise.id,
          text: widget.exercise.text,
          onContinue: widget.goToNext,
        ),
      ),
    );
  }
}
