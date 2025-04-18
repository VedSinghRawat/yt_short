import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sub_level_api.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/level/level.dart';

class SubLevelService {
  final LevelService levelService;
  final PathService pathService;

  SubLevelService(this.subLevelAPI, this.levelService, this.pathService);

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

    if (!await levelService.videoExists(levelId, videoFilename)) {
      SharedPref.removeValue(PrefKey.eTag(pathService.videoPath(levelId, videoFilename)));
    }
  }

  Future<void> downloadVideo(String levelId, String videoFilename) async {
    try {
      final videoData = await subLevelAPI.getVideo(levelId, videoFilename);

      if (videoData == null) return;

      await _storeVideo(levelId, videoFilename, videoData);
    } catch (e) {
      developer.log('Error downloading video: $e');
    }
  }

  Future<void> _storeVideo(String levelId, String videoFilename, Uint8List videoData) async {
    final file = File(pathService.fullVideoLocalPath(levelId, videoFilename));
    await Directory(file.parent.path).create(recursive: true);
    await file.writeAsBytes(videoData);
  }

  String getVideoUrl(String levelId, String videoFilename, BaseUrl baseUrl) {
    return '${baseUrl.url}${pathService.videoPath(levelId, videoFilename)}';
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);
  final pathService = ref.watch(pathServiceProvider);

  return SubLevelService(subLevelAPI, levelService, pathService);
});
