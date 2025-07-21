import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

@JsonSerializable()
class Progress {
  final int? level;
  final int? subLevel;
  final int? maxLevel;
  final int? maxSubLevel;
  final String? levelId;
  final int modified;

  Progress({this.level, this.subLevel, this.maxLevel, this.maxSubLevel, this.levelId, int? modified})
    : modified = modified ?? DateTime.now().millisecondsSinceEpoch;

  factory Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressToJson(this);

  Progress copyWith({int? level, int? subLevel, int? maxLevel, int? maxSubLevel, String? levelId, int? modified}) {
    return Progress(
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      maxSubLevel: maxSubLevel ?? this.maxSubLevel,
      levelId: levelId ?? this.levelId,
      modified: modified ?? this.modified,
    );
  }
}
