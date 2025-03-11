import 'package:json_annotation/json_annotation.dart';

part 'video.g.dart';

@JsonSerializable()
class Video {
  final String id;
  final String levelId;
  final int subLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Video({
    required this.id,
    required this.levelId,
    required this.subLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);

  Video copyWith({
    String? id,
    String? levelId,
    int? subLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Video(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      subLevel: subLevel ?? this.subLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
