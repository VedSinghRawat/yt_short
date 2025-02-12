// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechExercise _$SpeechExerciseFromJson(Map<String, dynamic> json) =>
    SpeechExercise(
      ytId: json['ytId'] as String,
      text: json['text'] as String,
      pauseAt: (json['pauseAt'] as num).toInt(),
      audioUrl: json['audioUrl'] as String,
      level: (json['level'] as num).toInt(),
      subLevel: (json['subLevel'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SpeechExerciseToJson(SpeechExercise instance) =>
    <String, dynamic>{
      'ytId': instance.ytId,
      'text': instance.text,
      'pauseAt': instance.pauseAt,
      'audioUrl': instance.audioUrl,
      'level': instance.level,
      'subLevel': instance.subLevel,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
