import 'package:json_annotation/json_annotation.dart';
import 'package:myapp/models/sublevel/sublevel_dto.dart';
import 'package:myapp/models/video/video.dart';

part 'speech_exercise.g.dart';

@JsonSerializable()
class SpeechExerciseDTO extends SubLevelDto {
  final String text;
  final int pauseAt;
  final String audioUrl;

  const SpeechExerciseDTO({
    required super.id,
    required super.zipNumber,
    required this.text,
    required this.pauseAt,
    required this.audioUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SpeechExerciseDTO.fromJson(Map<String, dynamic> json) => _$SpeechExerciseFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SpeechExerciseToJson(this);

  @override
  SpeechExerciseDTO copyWith({
    String? id,
    String? text,
    int? pauseAt,
    String? audioUrl,
    int? zipNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpeechExerciseDTO(
      id: id ?? this.id,
      text: text ?? this.text,
      pauseAt: pauseAt ?? this.pauseAt,
      audioUrl: audioUrl ?? this.audioUrl,
      zipNumber: zipNumber ?? this.zipNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
