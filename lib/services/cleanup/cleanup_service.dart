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
          sub.whenOrNull(
            video: (v) {
              for (var dialogue in v.dialogues) {
                final filename = dialogue.id;

                if (sublevelIdsByDialogueFilename[filename] == null) {
                  sublevelIdsByDialogueFilename[filename] = {};
                }

                sublevelIdsByDialogueFilename[filename]!.add(sub.id);
              }
            },
          );
        }
      }),
    );

    try {
      Directory levelsDir = Directory('${FileService.documentsDirectory.path}/levels');

      // Ensure directory exists and input is valid
      if (!await levelsDir.exists() ||
          deletableLevelIds.isEmpty ||
          deletableLevelIds.length - AppConstants.kProtectedIdsLength <= 0) {
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
        final folderPath = '${FileService.documentsDirectory.path}${PathService.levelDir(levelId)}';

        final level = levelById[levelId];
        if (level == null) continue;

        toBeDeletedPaths[levelId] = {};

        // Delete videos one by one and update size
        for (var (index, sub) in level.sub_levels.indexed) {
          if (sub.isVideo) {
            final videoPathEndpoint = PathService.sublevelAsset(levelId, sub.id, AssetType.video);
            final videoFile = FileService.getFile(videoPathEndpoint);
            if (!await videoFile.exists()) continue;

            final videoSize = await videoFile.length();

            toBeDeletedPaths[levelId]!.add(videoFile.path);
            etagsToClean.add(PathService.sublevelAsset(levelId, videoPathEndpoint, AssetType.video));

            totalSize -= videoSize;
          }
          // Handle audio files for speech exercises and drag-drop exercises
          if (sub.isSpeechExercise || sub.isArrangeExercise) {
            final audioPathEndpoint = PathService.sublevelAsset(levelId, sub.id, AssetType.audio);
            final audioFile = FileService.getFile(audioPathEndpoint);
            if (await audioFile.exists()) {
              final audioSize = await audioFile.length();
              toBeDeletedPaths[levelId]!.add(audioFile.path);

              etagsToClean.add(PathService.sublevelAsset(levelId, audioPathEndpoint, AssetType.audio));

              totalSize -= audioSize;
            }
          }

          // Handle image files for drag-drop exercises and fill exercises
          if (sub.isArrangeExercise || sub.isFillExercise) {
            final imagePathEndpoint = PathService.sublevelAsset(levelId, sub.id, AssetType.image);
            final imageFile = FileService.getFile(imagePathEndpoint);

            if (await imageFile.exists()) {
              final imageSize = await imageFile.length();
              toBeDeletedPaths[levelId]!.add(imageFile.path);

              etagsToClean.add(PathService.sublevelAsset(levelId, imagePathEndpoint, AssetType.image));

              totalSize -= imageSize;
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

      // Delete files, one compute call at a time
      for (final paths in toBeDeletedPaths.values) {
        await compute(_deleteFiles, paths.toList());
      }

      // Delete directories, one compute call at a time
      for (final dir in dirPathsToDelete) {
        await compute(_deleteFolderRecursively, dir);
      }

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
  final levelService = ref.read(levelServiceProvider);
  final levelController = ref.read(levelControllerProvider);
  return StorageCleanupService(levelService, levelController);
}
