import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sublevel_api.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/models/level/level.dart';

class SubLevelService {
  final LevelService levelService;

  SubLevelService(this.subLevelAPI, this.levelService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getFiles(LevelDTO levelDTO) async {
    await Future.wait(
      levelDTO.sub_levels.map((subLevelDTO) async {
        final videoData = await subLevelAPI.getVideo(levelDTO.id, subLevelDTO.videoFilename);
        final audioData =
            subLevelDTO.isSpeechExercise ? await subLevelAPI.getAudio(levelDTO.id, subLevelDTO.audioFilename!) : null;

        try {
          if (videoData != null) {
            final videoPath = PathService.videoLocal(levelDTO.id, subLevelDTO.videoFilename);
            await _store(levelDTO, videoPath, videoData);
          }

          if (audioData != null) {
            final audioPath = PathService.audioLocal(levelDTO.id, subLevelDTO.audioFilename!);
            await _store(levelDTO, audioPath, audioData);
          }
        } catch (e) {
          Console.log('Error saving video file for ${subLevelDTO.videoFilename}: $e');
        }
      }),
    );
  }

  Future<void> _store(LevelDTO levelDTO, String path, Uint8List data) async {
    final file = File(path);

    await file.parent.create(recursive: true);

    await file.writeAsBytes(data);
  }

  Future<void> getDialogueAudioFiles(LevelDTO levelDTO) async {
    final uniqueZipNums =
        levelDTO.sub_levels.expand((subLevelDto) => subLevelDto.dialogues).map((dialogue) => dialogue.zipNum).toSet();

    await Future.wait(
      uniqueZipNums.map((zipNum) async {
        final destinationDir = Directory(PathService.dialogueAudioDir);

        final zipData = await subLevelAPI.getDialogueZip(zipNum);

        if (zipData == null) return;

        File? tempZipFile;
        try {
          final tempZipPath = PathService.dialogueTempZip(zipNum);
          tempZipFile = File(tempZipPath);
          await tempZipFile.parent.create(recursive: true);
          await tempZipFile.writeAsBytes(zipData);

          await FileService.unzip(tempZipFile, destinationDir);
        } catch (e, _) {
          Console.log('Error processing dialogue zip $zipNum: $e');
        } finally {
          if (tempZipFile != null && await tempZipFile.exists()) {
            try {
              await tempZipFile.delete();
            } catch (e) {
              Console.log('Error deleting temporary zip file ${tempZipFile.path}: $e');
            }
          }
        }
      }),
    );
  }

  String getVideoUrl(String levelId, String videoFilename, BaseUrl baseUrl) {
    return '${baseUrl.url}${PathService.video(levelId, videoFilename)}';
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);

  return SubLevelService(subLevelAPI, levelService);
});
