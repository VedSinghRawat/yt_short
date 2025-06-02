import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

part 'video.g.dart';
part 'video.freezed.dart';

@freezed
class Video with _$Video {
  const factory Video({
    required String id,
    required List<SubDialogue> dialogues,
    required int level,
    required int index,
    required String levelId,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

@freezed
class VideoDTO with _$VideoDTO {
  const factory VideoDTO({required String id, required List<SubDialogue> dialogues}) = _VideoDTO;

  factory VideoDTO.fromJson(Map<String, dynamic> json) => _$VideoDTOFromJson(json);
}
