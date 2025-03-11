// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sublevel_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubLevelDto _$SubLevelDtoFromJson(Map<String, dynamic> json) => SubLevelDto(
      id: json['id'] as String,
      text: json['text'] as String?,
      pauseAt: (json['pauseAt'] as num?)?.toInt(),
      audioUrl: json['audioUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubLevelDtoToJson(SubLevelDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'pauseAt': instance.pauseAt,
      'audioUrl': instance.audioUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
