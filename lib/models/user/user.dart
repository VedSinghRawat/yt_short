import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class UserModel {
  final String email;
  final int? level;
  final int? subLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? lastSeen;
  final int? lastProgress;

  const UserModel({
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.level,
    this.subLevel,
    this.lastSeen,
    this.lastProgress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? level,
    int? subLevel,
    int? lastSeen,
    int? lastProgress,
  }) {
    return UserModel(
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      lastSeen: lastSeen ?? this.lastSeen,
      lastProgress: lastProgress ?? this.lastProgress,
    );
  }
}
