import 'package:json_annotation/json_annotation.dart';
import 'package:myapp/models/Level/level.dart';
import 'package:myapp/models/sublevel/sublevel_dto.dart';

part 'level_dto.g.dart';

@JsonSerializable()
class LevelDto extends Level {
  @JsonKey(fromJson: _subLevelsFromJson, toJson: _subLevelsToJson)
  final List<SubLevelDto> subLevels;

  LevelDto({
    required super.title,
    required super.nextLevelId,
    required super.prevLevelId,
    required this.subLevels,
  });

  factory LevelDto.fromJson(Map<String, dynamic> json) => _$LevelDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$LevelDtoToJson(this);

  static List<SubLevelDto> _subLevelsFromJson(List json) {
    return json.map((e) => SubLevelDto.fromJson(e)).toList();
  }

  static List<Map<String, dynamic>> _subLevelsToJson(List<SubLevelDto> subLevels) {
    return subLevels.map((e) => e.toJson()).toList();
  }
}
