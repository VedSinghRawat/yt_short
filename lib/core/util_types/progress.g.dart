// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgressImpl _$$ProgressImplFromJson(Map<String, dynamic> json) =>
    _$ProgressImpl(
      level: (json['level'] as num?)?.toInt(),
      subLevel: (json['subLevel'] as num?)?.toInt(),
      maxLevel: (json['maxLevel'] as num?)?.toInt(),
      maxSubLevel: (json['maxSubLevel'] as num?)?.toInt(),
      levelId: json['levelId'] as String?,
      modified: (json['modified'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ProgressImplToJson(_$ProgressImpl instance) =>
    <String, dynamic>{
      'level': instance.level,
      'subLevel': instance.subLevel,
      'maxLevel': instance.maxLevel,
      'maxSubLevel': instance.maxSubLevel,
      'levelId': instance.levelId,
      'modified': instance.modified,
    };
