// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechExerciseDTO _$SpeechExerciseFromJson(Map<String, dynamic> json) => SpeechExerciseDTO(
      id: json['id'] as String,
      text: json['text'] as String,
      pauseAt: (json['pauseAt'] as num).toInt(),
      audioUrl: json['audioUrl'] as String,
      levelId: json['levelId'] as String,
      subLevel: (json['subLevel'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SpeechExerciseToJson(SpeechExerciseDTO instance) => <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'pauseAt': instance.pauseAt,
      'audioUrl': instance.audioUrl,
      'levelId': instance.levelId,
      'subLevel': instance.subLevel,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
