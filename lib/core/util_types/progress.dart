import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'progress.freezed.dart';
part 'progress.g.dart';

@freezed
class Progress with _$Progress {
  const Progress._();

  const factory Progress({
    int? level,
    int? subLevel,
    int? maxLevel,
    int? maxSubLevel,
    String? levelId,
    int? modified,
  }) = _Progress;

  factory Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);
}
