import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

part 'fill_exercise.g.dart';
part 'fill_exercise.freezed.dart';

@freezed
class FillExercise with _$FillExercise {
  const factory FillExercise({
    required String id,
    required String text,
    required int level,
    required int index,
    required String levelId,
    required int blankIndex,
    required List<String> options,
    required int correctOption,
  }) = _FillExercise;

  factory FillExercise.fromJson(Map<String, dynamic> json) => _$FillExerciseFromJson(json);
}

@freezed
class FillExerciseDTO with _$FillExerciseDTO {
  const factory FillExerciseDTO({
    required String id,
    required String text,
    required List<String> options,
    required int correctOption,
    required SubLevelType type,
  }) = _FillExerciseDTO;

  factory FillExerciseDTO.fromJson(Map<String, dynamic> json) => _$FillExerciseDTOFromJson(json);
}
