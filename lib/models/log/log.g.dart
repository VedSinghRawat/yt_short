// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Log _$LogFromJson(Map<String, dynamic> json) => Log(
      videoId: (json['videoId'] as num).toInt(),
      subLevel: (json['subLevel'] as num).toInt(),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LogToJson(Log instance) => <String, dynamic>{
      'videoId': instance.videoId,
      'subLevel': instance.subLevel,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
