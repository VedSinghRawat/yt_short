import 'package:flutter/material.dart';
import 'package:myapp/features/speech_exercise/widgets/recognizer_button.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class ExerciseSentenceCard extends StatefulWidget {
  final VoidCallback onContinue;

  const ExerciseSentenceCard({
    super.key,
    required this.onContinue,
  });

  @override
  State<ExerciseSentenceCard> createState() => _ExerciseSentenceCardState();
}

class _ExerciseSentenceCardState extends State<ExerciseSentenceCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: widget.onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
