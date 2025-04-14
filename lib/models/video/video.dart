import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

part 'video.g.dart';
part 'video.freezed.dart';

@freezed
class Video with _$Video {
  const factory Video({
    required int level,
    required int index,
    required String levelId,
    required String videoFilename,
    required List<Dialogue> dialogues,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

@freezed
class VideoDTO with _$VideoDTO {
  const factory VideoDTO({
    required String videoFilename,
  }) = _VideoDTO;

  factory VideoDTO.fromJson(Map<String, dynamic> json) => _$VideoDTOFromJson(json);
}
