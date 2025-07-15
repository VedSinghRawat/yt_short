import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

part 'arrange_exercise.g.dart';
part 'arrange_exercise.freezed.dart';

@freezed
class ArrangeExercise with _$ArrangeExercise {
  const factory ArrangeExercise({
    required String id,
    required String text,
    required int level,
    required int index,
    required String levelId,
  }) = _ArrangeExercise;

  factory ArrangeExercise.fromJson(Map<String, dynamic> json) => _$ArrangeExerciseFromJson(json);
}

@freezed
class ArrangeExerciseDTO with _$ArrangeExerciseDTO {
  const factory ArrangeExerciseDTO({required String id, required String text, required SubLevelType type}) =
      _ArrangeExerciseDTO;

  factory ArrangeExerciseDTO.fromJson(Map<String, dynamic> json) => _$ArrangeExerciseDTOFromJson(json);
}
