// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityLog _$ActivityLogFromJson(Map<String, dynamic> json) => ActivityLog(
      subLevel: (json['subLevel'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      userEmail: json['userEmail'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$ActivityLogToJson(ActivityLog instance) => <String, dynamic>{
      'subLevel': instance.subLevel,
      'level': instance.level,
      'userEmail': instance.userEmail,
      'timestamp': instance.timestamp,
    };
