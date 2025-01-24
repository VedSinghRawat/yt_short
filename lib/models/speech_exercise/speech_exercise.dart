import 'package:json_annotation/json_annotation.dart';

part 'speech_exercise.g.dart';

@JsonSerializable()
class SpeechExercise {
  final String ytId;
  final String text;
  final int pauseAt;
  final String audioUrl;
  final int level;
  final int subLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpeechExercise({
    required this.ytId,
    required this.text,
    required this.pauseAt,
    required this.audioUrl,
    required this.level,
    required this.subLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpeechExercise.fromJson(Map<String, dynamic> json) => _$SpeechExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$SpeechExerciseToJson(this);

  SpeechExercise copyWith({
    String? ytId,
    String? text,
    int? pauseAt,
    String? audioUrl,
    int? level,
    int? subLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpeechExercise(
      ytId: ytId ?? this.ytId,
      text: text ?? this.text,
      pauseAt: pauseAt ?? this.pauseAt,
      audioUrl: audioUrl ?? this.audioUrl,
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
