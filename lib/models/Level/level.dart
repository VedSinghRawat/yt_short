import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

part 'level.g.dart';
part 'level.freezed.dart';

@freezed
class Level with _$Level {
  const factory Level({
    required String id,
    required String title,
    required String nextId,
    required String prevId,
  }) = _Level;

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);

  factory Level.fromLevelDTO(LevelDTO levelDTO) {
    return Level(
      id: levelDTO.id,
      title: levelDTO.title,
      nextId: levelDTO.nextId,
      prevId: levelDTO.prevId,
    );
  }
}

@freezed
class LevelDTO with _$LevelDTO {
  const factory LevelDTO({
    required String id,
    required String title,
    required String nextId,
    required String prevId,
    required List<SubLevelDTO> subLevels,
  }) = _LevelDTO;

  factory LevelDTO.fromJson(Map<String, dynamic> json) => _$LevelDTOFromJson(json);
}
