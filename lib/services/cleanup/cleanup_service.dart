import 'dart:developer' as developer show log;
import 'dart:io';
import 'dart:convert';
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
    try {
      Directory levelsDir = Directory('${FileService.documentsDirectory.path}/levels');

      if (!await levelsDir.exists()) return;

      final localLevelIds = await FileService.listNames(levelsDir, type: EntitiesType.folders);
      final orderedIds = levelController.orderedIds;
      if (orderedIds == null) return;

      int totalSize = await compute(FileService.getDirectorySize, levelsDir.path);

      if (totalSize < AppConstants.kMaxStorageSizeBytes) return;

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

      if (deletableLevelIds.isEmpty || deletableLevelIds.length - AppConstants.kProtectedIdsLength <= 0) return;

      final levelById = <String, LevelDTO>{};

      await Future.wait(
        deletableLevelIds.map((levelId) async {
          final level = await levelService.getLocalLevel(levelId);
          if (level == null) return null;

          levelById[levelId] = level;
        }),
      );

      // Build dialogueId -> referencing sublevelIds map from all local levels
      final dialogueIdToSubId = <String, Set<String>>{};
      for (final level in levelById.values) {
        for (final sub in level.sub_levels) {
          sub.whenOrNull(
            video: (v) {
              for (final dialogue in v.dialogues) {
                dialogueIdToSubId.putIfAbsent(dialogue.id, () => <String>{}).add(sub.id);
              }
            },
          );
        }
      }

      int i = 0;

      final toBeDeletedPaths = <String, Set<String>>{};
      final dirPathsToDelete = <String>{};
      final etagsToClean = <String>{};
      final deletedVideosIds = <String>{};
      final toBeDeletedDialoguePaths = <String>{};
      final dialogueIdToZipNum = <String, int>{};
      final zipNumToDialogueIds = <int, Set<String>>{};

      // get zip to check that all dialogues of same zip can be deleted or not
      Future<int?> getZipNumForDialogue(String dialogueId) async {
        if (dialogueIdToZipNum.containsKey(dialogueId)) return dialogueIdToZipNum[dialogueId];

        final dataFile = FileService.getFile(PathService.dialogueAsset(dialogueId, AssetType.data));
        if (!await dataFile.exists()) return null;
        try {
          final content = await dataFile.readAsString();
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;
          final zipNum = (jsonMap['zipNum'] as num?)?.toInt();
          if (zipNum != null) {
            dialogueIdToZipNum[dialogueId] = zipNum;
            zipNumToDialogueIds.putIfAbsent(zipNum, () => <String>{}).add(dialogueId);
          }
          return zipNum;
        } catch (_) {
          return null;
        }
      }

      // Start deleting until space is freed, also breaking the loop if the
      //protected levels are reached
      while (i < deletableLevelIds.length - AppConstants.kProtectedIdsLength) {
        final levelId = deletableLevelIds[i];
        final folderPath = '${FileService.documentsDirectory.path}${PathService.levelDir(levelId)}';

        final level = levelById[levelId];
        if (level == null) continue;

        toBeDeletedPaths[levelId] = <String>{};

        bool finishedAllSublevels = true;

        for (var (index, sub) in level.sub_levels.indexed) {
          String? endpoint;

          final assetType =
              sub.isVideo
                  ? AssetType.video
                  : (sub.isSpeechExercise || sub.isArrangeExercise)
                  ? AssetType.audio
                  : (sub.isArrangeExercise || sub.isFillExercise)
                  ? AssetType.image
                  : null;

          endpoint = assetType != null ? PathService.sublevelAsset(levelId, sub.id, assetType) : null;

          if (sub.isVideo) {
            deletedVideosIds.add(sub.id);
          }

          if (endpoint != null) {
            final file = FileService.getFile(endpoint);

            if (!await file.exists()) continue;

            final size = await file.length();

            toBeDeletedPaths[levelId]!.add(file.path);
            etagsToClean.add(endpoint);
            totalSize -= size;
          }

          if (totalSize < AppConstants.kDeleteCacheThreshold) {
            finishedAllSublevels = false;
            break;
          }

          // If this is the last sublevel and threshold not met, delete entire folder for this level
          if (index == level.sub_levels.length - 1) {
            dirPathsToDelete.add(folderPath);
            etagsToClean.add(PathService.levelJson(levelId));
            toBeDeletedPaths[levelId] = <String>{};
          }
        }

        // Stop processing more levels once we have freed enough space
        if (!finishedAllSublevels && totalSize < AppConstants.kDeleteCacheThreshold) {
          break;
        }

        i++;
      }

      await Future.wait(dialogueIdToSubId.keys.map((id) async => await getZipNumForDialogue(id)));

      // Determine which zipNums still have at least one dialogue referenced by a non-deleted sublevel
      final zipNumHasRemainingUsage = <int, bool>{};
      dialogueIdToSubId.forEach((dialogueId, subIds) {
        final zipNum = dialogueIdToZipNum[dialogueId];
        if (zipNum == null) return;
        final hasRemaining = subIds.any((sid) => !deletedVideosIds.contains(sid));
        if (hasRemaining) {
          zipNumHasRemainingUsage[zipNum] = true;
        }
      });

      final deletableZipNums = zipNumToDialogueIds.keys.where((z) => !(zipNumHasRemainingUsage[z] ?? false));

      // Queue dialogue audio files and zip files for deletion
      for (final zipNum in deletableZipNums) {
        final dialogueIds = zipNumToDialogueIds[zipNum] ?? const <String>{};
        for (final dialogueId in dialogueIds) {
          final audioEndpoint = PathService.dialogueAsset(dialogueId, AssetType.audio);
          final audioFile = FileService.getFile(audioEndpoint);

          if (await audioFile.exists()) {
            toBeDeletedDialoguePaths.add(audioFile.path);
            etagsToClean.add(audioEndpoint);
          }
        }

        final zipEndpoint = PathService.dialogueZip(zipNum);
        etagsToClean.add(zipEndpoint);
      }

      for (final paths in toBeDeletedPaths.values) {
        await compute(_deleteFiles, paths.toList());
      }

      if (toBeDeletedDialoguePaths.isNotEmpty) {
        await compute(_deleteFiles, toBeDeletedDialoguePaths.toList());
      }

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
