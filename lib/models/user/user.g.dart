// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      email: json['email'] as String,
      created: json['created'] as String,
      modified: json['modified'] as String,
      level: (json['level'] as num).toInt(),
      subLevel: (json['subLevel'] as num).toInt(),
      lastSeen: (json['lastSeen'] as num).toInt(),
      lastProgress: (json['lastProgress'] as num).toInt(),
      maxLevel: (json['maxLevel'] as num).toInt(),
      maxSubLevel: (json['maxSubLevel'] as num).toInt(),
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'email': instance.email,
      'level': instance.level,
      'subLevel': instance.subLevel,
      'created': instance.created,
      'modified': instance.modified,
      'maxLevel': instance.maxLevel,
      'maxSubLevel': instance.maxSubLevel,
      'lastSeen': instance.lastSeen,
      'lastProgress': instance.lastProgress,
      'role': _$UserRoleEnumMap[instance.role]!,
    };

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.student: 'student',
};
