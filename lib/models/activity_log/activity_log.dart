import 'package:json_annotation/json_annotation.dart';

part 'activity_log.g.dart';

@JsonSerializable()
class ActivityLog {
  final int subLevel;
  final int level;
  final String userEmail;
  final int timestamp;

  const ActivityLog({
    required this.subLevel,
    required this.level,
    required this.userEmail,
    required this.timestamp,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) => _$ActivityLogFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);
}
