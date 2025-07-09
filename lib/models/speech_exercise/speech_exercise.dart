import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'speech_exercise.g.dart';
part 'speech_exercise.freezed.dart';

@freezed
class SpeechExercise with _$SpeechExercise {
  const factory SpeechExercise({
    required String id,
    required String text,
    required int level,
    required int index,
    required String levelId,
  }) = _SpeechExercise;

  factory SpeechExercise.fromJson(Map<String, dynamic> json) => _$SpeechExerciseFromJson(json);
}

@freezed
class SpeechExerciseDTO with _$SpeechExerciseDTO {
  const factory SpeechExerciseDTO({required String id, required String text}) = _SpeechExerciseDTO;

  factory SpeechExerciseDTO.fromJson(Map<String, dynamic> json) => _$SpeechExerciseDTOFromJson(json);
}
