// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      email: json['email'] as String,
      level: (json['level'] as num).toInt(),
      levelId: json['levelId'] as String,
      subLevel: (json['subLevel'] as num).toInt(),
      created: json['created'] as String,
      modified: json['modified'] as String,
      maxLevel: (json['maxLevel'] as num).toInt(),
      maxSubLevel: (json['maxSubLevel'] as num).toInt(),
      lastSeen: (json['lastSeen'] as num).toInt(),
      lastProgress: (json['lastProgress'] as num).toInt(),
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'email': instance.email,
      'level': instance.level,
      'levelId': instance.levelId,
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
