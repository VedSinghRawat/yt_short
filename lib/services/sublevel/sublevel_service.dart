import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sublevel/sublevel_api.dart';
import 'package:myapp/core/console.dart';
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
    final audioData = subLevelDTO.isSpeechExercise ? await subLevelAPI.getAudio(levelId, subLevelDTO.id) : null;

    try {
      if (videoData != null) {
        final videoPath = PathService.sublevelVideo(levelId, subLevelDTO.id);
        await FileService.store(videoPath, videoData);
      }

      if (audioData != null) {
        final audioPath = PathService.sublevelAudio(levelId, subLevelDTO.id);
        await FileService.store(audioPath, audioData);
      }
    } catch (e) {
      Console.log('Error saving video file for ${subLevelDTO.id}: $e');
    }
  }
}

@riverpod
SubLevelService subLevelService(Ref ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);
  return SubLevelService(subLevelAPI, levelService);
}
