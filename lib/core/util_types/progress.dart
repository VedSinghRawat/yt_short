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
  }) : modified = DateTime.now().millisecondsSinceEpoch;

  factory Progress.fromJson(Map<String, dynamic> json) =>
      _$ProgressFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProgressToJson(this);

  Progress copyWith({
    int? level,
    int? subLevel,
    int? maxLevel,
    int? maxSubLevel,
    String? levelId,
  }) {
    return Progress(
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      maxSubLevel: maxSubLevel ?? this.maxSubLevel,
      levelId: levelId ?? this.levelId,
    );
  }
}
