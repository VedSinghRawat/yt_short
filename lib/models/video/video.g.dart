// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      ytId: json['ytId'] as String,
      level: (json['level'] as num).toInt(),
      subLevel: (json['subLevel'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
      'ytId': instance.ytId,
      'level': instance.level,
      'subLevel': instance.subLevel,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
