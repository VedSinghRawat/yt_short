import 'dart:developer' as developer show log;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cleanup_service.g.dart';

class StorageCleanupService {
  final LevelService levelService;
  final LevelControllerState levelController;

  StorageCleanupService(this.levelService, this.levelController);

  static Future<void> _deleteFiles(List<String> filePaths) async {
    await Future.wait(filePaths.map((filePath) => File(filePath).delete()));
  }

  static Future<void> _deleteFolderRecursively(String path) async {
    final folder = Directory(path);
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  /// Removes least-important cached levels while protecting nearby levels
  Future<void> cleanLocalFiles(String currentLevelId) async {
    final localLevelIds = await FileService.listNames(
      Directory('${FileService.documentsDirectory.path}/levels'),
      type: EntitiesType.folders,
    );
    final orderedIds = levelController.orderedIds;
    if (orderedIds == null) return;

    final Map<String, int> idToIndexMap = {for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i};

    final int currentIndex = idToIndexMap[currentLevelId] ?? -1;

    // renaming the localLevelIds to deletableIds before sorting for semantics
    final deletableLevelIds = localLevelIds;
    // sorting the deletableIds based on the distance from the current level and moving the
    // protected level to the end
    deletableLevelIds.sort((idA, idB) {
      final int indexA = idToIndexMap[idA] ?? -1;
      final int indexB = idToIndexMap[idB] ?? -1;

      final int distanceA = indexA - currentIndex;
      final int distanceB = indexB - currentIndex;

      // Keep protected levels at the end
      if (_isProtectedLevel(distanceA)) return 1;
      if (_isProtectedLevel(distanceB)) return -1;

      return distanceA.abs().compareTo(distanceB.abs());
    });

    final sublevelIdsByDialogueFilename = <String, Set<String>>{};
    final levelById = <String, LevelDTO>{};

    await Future.wait(
      deletableLevelIds.map((levelId) async {
        final level = await levelService.getLocalLevel(levelId);
        if (level == null) return null;

        levelById[levelId] = level;

        for (var sub in level.sub_levels) {
          for (var dialogue in sub.dialogues) {
            final filename = dialogue.id;

            if (sublevelIdsByDialogueFilename[filename] == null) {
              sublevelIdsByDialogueFilename[filename] = {};
            }

            sublevelIdsByDialogueFilename[filename]!.add(sub.id);
          }
        }
      }),
    );

    try {
      Directory levelsDir = Directory('${FileService.documentsDirectory.path}/levels');

      // Ensure directory exists and input is valid
      if (!await levelsDir.exists() ||
          deletableLevelIds.isEmpty ||
          deletableLevelIds.length - AppConstants.kProtectedIdsLength == 0) {
        return;
      }

      int totalSize = await compute(FileService.getDirectorySize, levelsDir);
      if (totalSize < AppConstants.kMaxStorageSizeBytes) return;

      int i = 0;

      final toBeDeletedPaths = <String, Set<String>>{};
      final dirPathsToDelete = <String>{};
      final etagsToClean = <String>{};

      // Start deleting until space is freed, also breaking the loop if the
      //protected levels are reached
      while (i < deletableLevelIds.length - AppConstants.kProtectedIdsLength) {
        final levelId = deletableLevelIds[i];
        final folderPath = PathService.levelDir(levelId);

        final level = levelById[levelId];
        if (level == null) continue;

        toBeDeletedPaths[levelId] = {};

        // Delete videos one by one and update size
        for (var (index, sub) in level.sub_levels.indexed) {
          final videoPath = PathService.sublevelVideo(levelId, sub.id);
          final videoFile = File(videoPath);
          if (!await videoFile.exists()) continue;

          final videoSize = await videoFile.length();

          toBeDeletedPaths[levelId]!.add(videoPath);
          etagsToClean.add(PathService.sublevelVideo(levelId, videoPath.split('/').last.replaceAll('.mp4', '')));

          totalSize -= videoSize;

          if (sub.isSpeechExercise) {
            final audioPath = PathService.sublevelAudio(levelId, sub.id);
            final audioFile = File(audioPath);
            if (await audioFile.exists()) {
              final audioSize = await audioFile.length();
              toBeDeletedPaths[levelId]!.add(audioPath);

              etagsToClean.add(PathService.sublevelVideo(levelId, audioPath.split('/').last.replaceAll('.mp3', '')));

              totalSize -= audioSize;
            }
          }

          // delete full folder if there are no videos left
          if (index == level.sub_levels.length - 1) {
            dirPathsToDelete.add(folderPath);

            etagsToClean.add(PathService.levelJson(levelId));
            toBeDeletedPaths[levelId] = {};
            continue;
          }

          if (totalSize < AppConstants.kDeleteCacheThreshold) {
            break;
          }
        }

        i++;
      }

      await Future.wait(toBeDeletedPaths.values.map((paths) => compute(_deleteFiles, paths.toList())));
      await Future.wait(dirPathsToDelete.map((dir) => compute(_deleteFolderRecursively, dir)));
      await Future.wait(etagsToClean.map((eTag) => SharedPref.removeValue(PrefKey.eTag(eTag))));
    } catch (e) {
      developer.log("Error in cleanup process: $e");
    }
  }

  /// Prevents deletion of current, previous and next two levels
  bool _isProtectedLevel(int dist) =>
      (dist < 0 && dist.abs() <= AppConstants.kMaxPreviousLevelsToKeep) || dist <= AppConstants.kMaxNextLevelsToKeep;
}

@riverpod
StorageCleanupService storageCleanupService(Ref ref) {
  final levelService = ref.watch(levelServiceProvider);
  final levelController = ref.watch(levelControllerProvider);
  return StorageCleanupService(levelService, levelController);
}
