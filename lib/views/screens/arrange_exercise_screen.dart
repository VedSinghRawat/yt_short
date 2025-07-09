import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/arrange_exercise/arrange_exercise.dart';

class ArrangeExerciseScreen extends ConsumerStatefulWidget {
  final ArrangeExercise exercise;
  final VoidCallback goToNext;

  const ArrangeExerciseScreen({super.key, required this.exercise, required this.goToNext});

  @override
  ConsumerState<ArrangeExerciseScreen> createState() => _ArrangeExerciseScreenState();
}

class _ArrangeExerciseScreenState extends ConsumerState<ArrangeExerciseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [Text(widget.exercise.text)])));
  }
}
