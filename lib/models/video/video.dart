import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'video.g.dart';
part 'video.freezed.dart';

@freezed
class Video with _$Video {
  const factory Video({
    required int level,
    required int index,
    required String levelId,
    required String videoFilename,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

@freezed
class VideoDTO with _$VideoDTO {
  const factory VideoDTO({
    required String videoFilename,
    required int zipNum,
  }) = _VideoDTO;

  factory VideoDTO.fromJson(Map<String, dynamic> json) => _$VideoDTOFromJson(json);
}
