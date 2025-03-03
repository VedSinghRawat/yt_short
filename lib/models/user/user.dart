import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class UserModel {
  final String email;
  final int level;
  final int subLevel;
  final String created;
  final String modified;
  final int maxLevel;
  final int maxSubLevel;
  final int lastSeen;
  final int lastProgress;
  final UserRole role;

  const UserModel({
    required this.email,
    required this.created,
    required this.modified,
    required this.level,
    required this.subLevel,
    required this.lastSeen,
    required this.lastProgress,
    required this.maxLevel,
    required this.maxSubLevel,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? email,
    String? created,
    String? modified,
    int? level,
    int? subLevel,
    int? lastSeen,
    int? lastProgress,
    int? maxLevel,
    int? maxSubLevel,
    UserRole? role,
  }) {
    return UserModel(
      email: email ?? this.email,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      lastSeen: lastSeen ?? this.lastSeen,
      lastProgress: lastProgress ?? this.lastProgress,
      maxLevel: maxLevel ?? this.maxLevel,
      maxSubLevel: maxSubLevel ?? this.maxSubLevel,
      role: role ?? this.role,
    );
  }
}

enum UserRole {
  admin,
  student,
}
