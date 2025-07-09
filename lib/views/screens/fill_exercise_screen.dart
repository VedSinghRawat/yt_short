import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/fill_exercise/fill_exercise.dart';

class FillExerciseScreen extends ConsumerStatefulWidget {
  final FillExercise exercise;
  final VoidCallback goToNext;

  const FillExerciseScreen({super.key, required this.exercise, required this.goToNext});

  @override
  ConsumerState<FillExerciseScreen> createState() => _FillExerciseScreenState();
}

class _FillExerciseScreenState extends ConsumerState<FillExerciseScreen> {
  int? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [Text(widget.exercise.text)])));
  }
}
