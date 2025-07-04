import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

part 'level.g.dart';
part 'level.freezed.dart';

@freezed
class Level with _$Level {
  const factory Level({required String id, required String title, required List<String> subLevelIds}) = _Level;

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);

  factory Level.fromLevelDTO(LevelDTO levelDTO) {
    return Level(id: levelDTO.id, title: levelDTO.title, subLevelIds: levelDTO.sub_levels.map((e) => e.id).toList());
  }
}

@freezed
class LevelDTO with _$LevelDTO {
  const factory LevelDTO({
    required String id,
    required String title,
    // ignore: non_constant_identifier_names
    required List<SubLevelDTO> sub_levels,
  }) = _LevelDTO;

  factory LevelDTO.fromJson(Map<String, dynamic> json) => _$LevelDTOFromJson(json);
}
