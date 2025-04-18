import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sublevel_api.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/models/level/level.dart';

class SubLevelService {
  final LevelService levelService;
  final FileService fileService;

  SubLevelService(this.subLevelAPI, this.levelService, this.fileService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getVideoFiles(LevelDTO levelDTO) async {
    // First fetch all video files in parallel
    await Future.wait(
      levelDTO.sub_levels.map((subLevelDTO) async {
        final videoData = await subLevelAPI.getVideo(levelDTO.id, subLevelDTO.videoFilename);

        return videoData;
      }),
    );
  }

  Future<void> getDialogueAudioFiles(LevelDTO levelDTO) async {
    // 1. Find all unique zipNums needed for this level
    final uniqueZipNums =
        levelDTO.sub_levels
            .expand((subLevelDto) => subLevelDto.dialogues)
            .map((dialogue) => dialogue.zipNum)
            .toSet();

    // 2. Process each zipNum
    await Future.wait(
      uniqueZipNums.map((zipNum) async {
        // Destination is now the single base directory for all audios
        final destinationDir = Directory(levelService.dialogueAudioBaseDirPath);

        // 4. Fetch the zip file data
        final zipData = await subLevelAPI.getDialogueZip(zipNum);

        if (zipData == null) return; // Skip if no data

        File? tempZipFile;
        try {
          final tempZipPath = levelService.getDialogueAudioTempZipPath(zipNum);
          tempZipFile = File(tempZipPath);
          await tempZipFile.parent.create(recursive: true);
          await tempZipFile.writeAsBytes(zipData);

          await fileService.unzip(tempZipFile, destinationDir);
        } catch (e, stackTrace) {
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

  String getVideoUrl(String levelId, String videoFilename) {
    return '${BaseUrl.cloudflare.url}${levelService.getVideoPathEndPoint(levelId, videoFilename)}';
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);
  final fileService = ref.watch(fileServiceProvider);

  return SubLevelService(subLevelAPI, levelService, fileService);
});
