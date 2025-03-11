import 'package:json_annotation/json_annotation.dart';

part 'level.g.dart';

@JsonSerializable()
class Level {
  final String title;
  final String nextLevelId;
  final String prevLevelId;

  Level({
    required this.title,
    required this.nextLevelId,
    required this.prevLevelId,
  });

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
  Map<String, dynamic> toJson() => _$LevelToJson(this);
}
