import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  @JsonKey(name: 'level')
  final int? level;
  @JsonKey(name: 'sub_level')
  final int? subLevel;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.level,
    this.subLevel,
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
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
    );
  }
}
