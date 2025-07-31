import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';
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

    if (oldWidget.isVisible && !widget.isVisible) {
      Future(() {
        if (mounted) {
          ref.read(speechProvider(targetWords: widget.exercise.text.split(' ')).notifier).resetState();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsiveness = ResponsivenessService(context);

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;
            final padding = responsiveness.getResponsiveValues(mobile: 16, tablet: 24, largeTablet: 32);

            return Padding(
              padding: EdgeInsets.fromLTRB(padding, isPortrait ? kToolbarHeight + padding : padding, padding, padding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
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
          },
        ),
      ),
    );
  }
}
