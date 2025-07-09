import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sublevel/sublevel_api.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_service.g.dart';

class SubLevelService {
  final LevelService levelService;

  SubLevelService(this.subLevelAPI, this.levelService);

  final ISubLevelAPI subLevelAPI;

  Future<void> downloadData(SubLevelDTO subLevelDTO, String levelId) async {
    final videoData = await subLevelAPI.getVideo(levelId, subLevelDTO.id);
    final audioData =
        (subLevelDTO.isSpeechExercise || subLevelDTO.isArrangeExercise)
            ? await subLevelAPI.getAudio(levelId, subLevelDTO.id)
            : null;
    final imageData =
        (subLevelDTO.isArrangeExercise || subLevelDTO.isFillExercise)
            ? await subLevelAPI.getImage(levelId, subLevelDTO.id)
            : null;

    try {
      if (videoData != null) {
        final videoPath = PathService.sublevelAsset(levelId, subLevelDTO.id, AssetType.video);
        await FileService.store(videoPath, videoData);
      }

      if (audioData != null) {
        final audioPath = PathService.sublevelAsset(levelId, subLevelDTO.id, AssetType.audio);
        await FileService.store(audioPath, audioData);
      }

      if (imageData != null) {
        final imagePath = PathService.sublevelAsset(levelId, subLevelDTO.id, AssetType.image);
        await FileService.store(imagePath, imageData);
      }
    } catch (e) {
      developer.log(e.toString(), name: 'SubLevelService');
    }
  }
}

@riverpod
SubLevelService subLevelService(Ref ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);
  return SubLevelService(subLevelAPI, levelService);
}
