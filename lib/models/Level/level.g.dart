// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level _$LevelFromJson(Map<String, dynamic> json) => Level(
      title: json['title'] as String,
      nextLevelId: json['nextLevelId'] as String,
      prevLevelId: json['prevLevelId'] as String,
    );

Map<String, dynamic> _$LevelToJson(Level instance) => <String, dynamic>{
      'title': instance.title,
      'nextLevelId': instance.nextLevelId,
      'prevLevelId': instance.prevLevelId,
    };
