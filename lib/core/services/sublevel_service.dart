import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/sublevel_api.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/models/level/level.dart';

class SubLevelService {
  final LevelService levelService;

  SubLevelService(this.subLevelAPI, this.levelService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getVideoFiles(
    LevelDTO levelDTO,
  ) async {
    // First fetch all video files in parallel
    await Future.wait(
      levelDTO.sub_levels.map(
        (subLevelDTO) async {
          final videoDataEither = await subLevelAPI.getVideo(
            levelDTO.id,
            subLevelDTO.videoFilename,
          );

          return switch (videoDataEither) {
            Left() => null,
            Right(value: final videoData) when videoData == null => null,
            Right(value: final videoData) => () async {
                final file = File(
                  levelService.getVideoPath(levelDTO.id, subLevelDTO.videoFilename),
                );
                await Directory(file.parent.path).create(recursive: true);
                await file.writeAsBytes(videoData!);
              }(),
          };
        },
      ),
    );
  }

  String getVideoUrl(String levelId, String videoFilename) {
    return '${BaseUrl.cloudflare.url}${levelService.getVideoPathEndPoint(levelId, videoFilename)}';
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);

  return SubLevelService(subLevelAPI, levelService);
});
