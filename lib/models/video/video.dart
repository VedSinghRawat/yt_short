import 'package:json_annotation/json_annotation.dart';

part 'video.g.dart';

@JsonSerializable()
class Video {
  final String ytId;
  final int level;
  final int subLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Video({
    required this.ytId,
    required this.level,
    required this.subLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoToJson(this);

  Video copyWith({
    String? ytId,
    int? level,
    int? subLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Video(
      ytId: ytId ?? this.ytId,
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
