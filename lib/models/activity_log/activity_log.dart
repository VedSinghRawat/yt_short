import 'package:json_annotation/json_annotation.dart';
import 'package:myapp/core/shared_pref.dart';

part 'activity_log.g.dart';

@JsonSerializable()
class ActivityLog implements SharedPrefClass {
  final int subLevel;
  final int level;
  final String userEmail;
  final int timestamp;

  ActivityLog({
    required this.subLevel,
    required this.level,
    required this.userEmail,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ActivityLogToJson(this);
}
