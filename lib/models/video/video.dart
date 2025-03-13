import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'video.g.dart';
part 'video.freezed.dart';

@freezed
class Video with _$Video {
  const factory Video({
    required int level,
    required int subLevel,
    required String levelId,
    required String videoFileName,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

@freezed
class VideoDTO with _$VideoDTO {
  const factory VideoDTO({
    required String videoFileName,
    required int zip,
  }) = _VideoDTO;

  factory VideoDTO.fromJson(Map<String, dynamic> json) => _$VideoDTOFromJson(json);
}
