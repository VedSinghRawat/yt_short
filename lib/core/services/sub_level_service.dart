import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/sub_level_api.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/level/level.dart';

class SubLevelService {
  final LevelService levelService;

  SubLevelService(this.subLevelAPI, this.levelService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getVideoFiles(LevelDTO levelDTO) async {
    // First fetch all video files in parallel
    await Future.wait(
      levelDTO.sub_levels.map(
        (subLevelDTO) => downloadVideo(levelDTO.id, subLevelDTO.videoFilename),
      ),
    );
  }

  Future<void> getSubLevelFile(String levelId, String videoFilename) async {
    await downloadVideo(levelId, videoFilename);

    if (!await levelService.doesVideoExists(levelId, videoFilename)) {
      SharedPref.removeValue(PrefKey.eTag(levelService.getVideoPath(levelId, videoFilename)));
    }
  }

  Future<void> downloadVideo(String levelId, String videoFilename) async {
    final videoDataEither = await subLevelAPI.getVideo(levelId, videoFilename);

    return switch (videoDataEither) {
      Left() => null,
      Right(value: final videoData) when videoData == null => null,
      Right(value: final videoData) => _storeVideo(levelId, videoFilename, videoData!),
    };
  }

  Future<void> _storeVideo(String levelId, String videoFilename, Uint8List videoData) async {
    final file = File(levelService.getFullVideoPath(levelId, videoFilename));
    await Directory(file.parent.path).create(recursive: true);
    await file.writeAsBytes(videoData);
  }

  String getVideoUrl(String levelId, String videoFilename, BaseUrl baseUrl) {
    return '${baseUrl.url}${levelService.getVideoPath(levelId, videoFilename)}';
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);

  return SubLevelService(subLevelAPI, levelService);
});
