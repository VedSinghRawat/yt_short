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

  Future<int?> _getZipNumForDialogue(
    String dialogueId,
    Map<String, int> dialogueIdToZipNum,
    Map<int, Set<String>> zipNumToDialogueIds,
  ) async {
    if (dialogueIdToZipNum.containsKey(dialogueId)) return dialogueIdToZipNum[dialogueId];

    final dialogueDataFile = FileService.getFile(PathService.dialogueAsset(dialogueId, AssetType.data));

    if (!await dialogueDataFile.exists()) return null;

    try {
      final content = await dialogueDataFile.readAsString();
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

  Future<void> cleanLocalFiles(String currentLevelId) async {
    try {
      Directory levelsDir = Directory('${FileService.documentsDirectory.path}/levels');

      if (!await levelsDir.exists()) return;

      final deletableLevelIds = await FileService.listNames(levelsDir, type: EntitiesType.folders);
      final orderedIds = levelController.orderedIds;

      if (orderedIds == null) return;

      int totalSize = await compute(FileService.getDirectorySize, levelsDir.path);

      if (totalSize < AppConstants.kMaxStorageSizeBytes) return;

      final Map<String, int> idToIndexMap = {for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i};

      final int currentIndex = idToIndexMap[currentLevelId] ?? -1;

      deletableLevelIds.sort((idA, idB) {
        final int indexA = idToIndexMap[idA] ?? -1;
        final int indexB = idToIndexMap[idB] ?? -1;

        final int distanceA = indexA - currentIndex;
        final int distanceB = indexB - currentIndex;

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

      final dialogueIdToCount = <String, int>{};

      for (final level in levelById.values) {
        for (final sub in level.sub_levels) {
          sub.whenOrNull(
            video: (v) {
              for (final dialogue in v.dialogues) {
                dialogueIdToCount.putIfAbsent(dialogue.id, () => 0);
                dialogueIdToCount[dialogue.id] = dialogueIdToCount[dialogue.id]! + 1;
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
      final dialogueIdToZipNum = <String, int>{};
      final zipNumToDialogueIds = <int, Set<String>>{};

      while (i < deletableLevelIds.length - AppConstants.kProtectedIdsLength) {
        final levelId = deletableLevelIds[i];
        final folderPath = '${FileService.documentsDirectory.path}${PathService.levelDir(levelId)}';

        final level = levelById[levelId];
        if (level == null) continue;

        toBeDeletedPaths[levelId] = <String>{};

        bool finishedAllSublevels = true;

        for (var (index, sub) in level.sub_levels.indexed) {
          final assetType = switch (true) {
            _ when sub.isVideo => AssetType.video,
            _ when sub.isSpeechExercise || sub.isArrangeExercise => AssetType.audio,
            _ when sub.isArrangeExercise || sub.isFillExercise => AssetType.image,
            _ => null,
          };

          if (assetType == null) continue;

          final endpoint = PathService.sublevelAsset(levelId, sub.id, assetType);

          if (sub.isVideo) {
            deletedVideosIds.add(sub.id);
          }

          final file = FileService.getFile(endpoint);

          if (!await file.exists()) continue;

          final size = await file.length();

          toBeDeletedPaths[levelId]!.add(file.path);
          etagsToClean.add(endpoint);
          totalSize -= size;

          if (totalSize < AppConstants.kDeleteCacheThreshold) {
            finishedAllSublevels = false;
            break;
          }

          if (index == level.sub_levels.length - 1) {
            dirPathsToDelete.add(folderPath);
            etagsToClean.add(PathService.levelJson(levelId));
            toBeDeletedPaths[levelId] = <String>{};
          }
        }

        if (!finishedAllSublevels && totalSize < AppConstants.kDeleteCacheThreshold) {
          break;
        }

        i++;
      }

      if (deletedVideosIds.isNotEmpty) {
        await Future.wait(
          dialogueIdToCount.keys.map(
            (id) async => await _getZipNumForDialogue(id, dialogueIdToZipNum, zipNumToDialogueIds),
          ),
        );

        final Set<int> zipNumHasRemainingUsage = {};

        dialogueIdToCount.forEach((dialogueId, count) {
          final zipNum = dialogueIdToZipNum[dialogueId];
          if (zipNum == null) return;
          if (count > 0) {
            zipNumHasRemainingUsage.add(zipNum);
          }
        });

        final deletableZipNums = zipNumToDialogueIds.keys.where((z) => !zipNumHasRemainingUsage.contains(z));

        for (final zipNum in deletableZipNums) {
          final dialogueIds = zipNumToDialogueIds[zipNum] ?? const <String>{};
          for (final dialogueId in dialogueIds) {
            for (final type in [AssetType.audio, AssetType.data]) {
              final endpoint = PathService.dialogueAsset(dialogueId, type);
              final file = FileService.getFile(endpoint);
              if (await file.exists()) {
                if (!toBeDeletedPaths.containsKey(dialogueId)) {
                  toBeDeletedPaths[dialogueId] = <String>{};
                }

                toBeDeletedPaths[dialogueId]!.add(file.path);
                etagsToClean.add(endpoint);
              }
            }
          }

          final zipEndpoint = PathService.dialogueZip(zipNum);
          etagsToClean.add(zipEndpoint);
        }
      }

      for (final paths in toBeDeletedPaths.values) {
        await compute(_deleteFiles, paths.toList());
      }

      for (final dir in dirPathsToDelete) {
        await compute(_deleteFolderRecursively, dir);
      }

      await Future.wait(etagsToClean.map((eTag) => SharedPref.removeValue(PrefKey.eTag(eTag))));
    } catch (e) {
      developer.log("Error in cleanup process: $e");
    }
  }

  bool _isProtectedLevel(int dist) =>
      (dist < 0 && dist.abs() <= AppConstants.kMaxPreviousLevelsToKeep) || dist <= AppConstants.kMaxNextLevelsToKeep;
}

@riverpod
StorageCleanupService storageCleanupService(Ref ref) {
  final levelService = ref.read(levelServiceProvider);
  final levelController = ref.read(levelControllerProvider);
  return StorageCleanupService(levelService, levelController);
}
