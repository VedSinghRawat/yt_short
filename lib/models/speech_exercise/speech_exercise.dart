import 'package:json_annotation/json_annotation.dart';

part 'speech_exercise.g.dart';

@JsonSerializable()
class SpeechExercise {
  final int id;
  @JsonKey(name: 'yt_id')
  final String ytId;
  @JsonKey(name: 'text_to_speak')
  final String textToSpeak;
  @JsonKey(name: 'pause_at')
  final int pauseAt;
  @JsonKey(name: 'audio_url')
  final String audioUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const SpeechExercise({
    required this.id,
    required this.ytId,
    required this.textToSpeak,
    required this.pauseAt,
    required this.audioUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpeechExercise.fromJson(Map<String, dynamic> json) => _$SpeechExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$SpeechExerciseToJson(this);

  SpeechExercise copyWith({
    int? id,
    String? ytId,
    String? textToSpeak,
    int? pauseAt,
    String? audioUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpeechExercise(
      id: id ?? this.id,
      ytId: ytId ?? this.ytId,
      textToSpeak: textToSpeak ?? this.textToSpeak,
      pauseAt: pauseAt ?? this.pauseAt,
      audioUrl: audioUrl ?? this.audioUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
