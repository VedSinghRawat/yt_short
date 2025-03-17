// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SpeechExerciseImpl _$$SpeechExerciseImplFromJson(Map<String, dynamic> json) =>
    _$SpeechExerciseImpl(
      text: json['text'] as String,
      pauseAt: (json['pauseAt'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      index: (json['index'] as num).toInt(),
      levelId: json['levelId'] as String,
      videoFileName: json['videoFileName'] as String,
    );

Map<String, dynamic> _$$SpeechExerciseImplToJson(
        _$SpeechExerciseImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'pauseAt': instance.pauseAt,
      'level': instance.level,
      'index': instance.index,
      'levelId': instance.levelId,
      'videoFileName': instance.videoFileName,
    };

_$SpeechExerciseDTOImpl _$$SpeechExerciseDTOImplFromJson(
        Map<String, dynamic> json) =>
    _$SpeechExerciseDTOImpl(
      videoFileName: json['videoFileName'] as String,
      text: json['text'] as String,
      pauseAt: (json['pauseAt'] as num).toInt(),
      zip: (json['zip'] as num).toInt(),
    );

Map<String, dynamic> _$$SpeechExerciseDTOImplToJson(
        _$SpeechExerciseDTOImpl instance) =>
    <String, dynamic>{
      'videoFileName': instance.videoFileName,
      'text': instance.text,
      'pauseAt': instance.pauseAt,
      'zip': instance.zip,
    };
