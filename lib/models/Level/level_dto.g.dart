// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LevelDto _$LevelDtoFromJson(Map<String, dynamic> json) => LevelDto(
      title: json['title'] as String,
      nextLevelId: json['nextLevelId'] as String,
      prevLevelId: json['prevLevelId'] as String,
      subLevels: LevelDto._subLevelsFromJson(json['subLevels'] as List),
    );

Map<String, dynamic> _$LevelDtoToJson(LevelDto instance) => <String, dynamic>{
      'title': instance.title,
      'nextLevelId': instance.nextLevelId,
      'prevLevelId': instance.prevLevelId,
      'subLevels': LevelDto._subLevelsToJson(instance.subLevels),
    };
