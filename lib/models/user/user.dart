import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String email,
    required int level,
    required String levelId,
    required int subLevel,
    required String created,
    required String modified,
    required int maxLevel,
    required int maxSubLevel,
    required int lastSeen,
    required int lastProgress,
    required UserRole role,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  bool get isAdmin => role == UserRole.admin;
}

enum UserRole {
  admin,
  student,
}
