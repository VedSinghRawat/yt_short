import 'package:json_annotation/json_annotation.dart';

part 'log.g.dart';

@JsonSerializable()
class Log {
  final int videoId;
  final int subLevel;
  final String userId;
  final DateTime createdAt;

  const Log({
    required this.videoId,
    required this.subLevel,
    required this.userId,
    required this.createdAt,
  });

  factory Log.fromJson(Map<String, dynamic> json) => _$LogFromJson(json);
  Map<String, dynamic> toJson() => _$LogToJson(this);
}
