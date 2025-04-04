import 'package:json_annotation/json_annotation.dart';
import 'package:myapp/core/shared_pref.dart';

part 'progress.g.dart';

@JsonSerializable()
class Progress implements SharedPrefClass {
  final int? level;
  final int? subLevel;
  final int? maxLevel;
  final int? maxSubLevel;
  final String? levelId;
  final int modified;

  Progress({
    this.level,
    this.subLevel,
    this.maxLevel,
    this.maxSubLevel,
    this.levelId,
    int? modified,
  }) : modified = modified ?? DateTime.now().millisecondsSinceEpoch;

  factory Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProgressToJson(this);
}
