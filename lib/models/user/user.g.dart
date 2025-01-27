// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      email: json['email'] as String,
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      level: (json['level'] as num?)?.toInt(),
      subLevel: (json['subLevel'] as num?)?.toInt(),
      lastSeen: (json['lastSeen'] as num?)?.toInt(),
      lastProgress: (json['lastProgress'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'email': instance.email,
      'level': instance.level,
      'subLevel': instance.subLevel,
      'created': instance.created.toIso8601String(),
      'modified': instance.modified.toIso8601String(),
      'lastSeen': instance.lastSeen,
      'lastProgress': instance.lastProgress,
    };
