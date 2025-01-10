// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpeechExercise _$SpeechExerciseFromJson(Map<String, dynamic> json) =>
    SpeechExercise(
      id: (json['id'] as num).toInt(),
      ytId: json['yt_id'] as String,
      textToSpeak: json['text_to_speak'] as String,
      pauseAt: (json['pause_at'] as num).toInt(),
      playAt: (json['play_at'] as num).toInt(),
      audioUrl: json['audio_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SpeechExerciseToJson(SpeechExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'yt_id': instance.ytId,
      'text_to_speak': instance.textToSpeak,
      'pause_at': instance.pauseAt,
      'play_at': instance.playAt,
      'audio_url': instance.audioUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
