// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LevelImpl _$$LevelImplFromJson(Map<String, dynamic> json) => _$LevelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      nextId: json['nextId'] as String?,
      prevId: json['prevId'] as String?,
      subLevelCount: (json['subLevelCount'] as num).toInt(),
    );

Map<String, dynamic> _$$LevelImplToJson(_$LevelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'nextId': instance.nextId,
      'prevId': instance.prevId,
      'subLevelCount': instance.subLevelCount,
    };

_$LevelDTOImpl _$$LevelDTOImplFromJson(Map<String, dynamic> json) =>
    _$LevelDTOImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      nextId: json['nextId'] as String?,
      prevId: json['prevId'] as String?,
      subLevels: (json['subLevels'] as List<dynamic>)
          .map((e) => SubLevelDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$LevelDTOImplToJson(_$LevelDTOImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'nextId': instance.nextId,
      'prevId': instance.prevId,
      'subLevels': instance.subLevels,
    };
