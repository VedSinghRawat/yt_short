import 'dart:developer' as developer show log;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';

class StorageCleanupService {
  final FileService fileService;
  final LevelService levelService;

  StorageCleanupService(this.fileService, this.levelService);

  /// Main cleanup logic — removes folders from cache if total size exceeds threshold
  Future<void> cleanLevels(List<String> orderedIds) async {
    try {
      Directory targetDir = Directory(levelService.levelsDocDirPath);

      // Ensure directory exists and input is valid
      if (!await targetDir.exists() ||
          orderedIds.isEmpty ||
          orderedIds.length - kProtectedIdsLength == 0) {
        return;
      }

      // Check total size of the cache folder
      int totalSize = await compute(FileService.getDirectorySize, targetDir);

      // No need to clean if under limit
      if (totalSize < kMaxStorageSizeBytes) {
        return;
      }

      int i = 0;
      // Start deleting until space is freed
      while (i < orderedIds.length - kProtectedIdsLength) {
        final id = orderedIds[i];
        final folderPath = levelService.getLevelPath(id);
        final folder = Directory(folderPath);

        if (!await folder.exists()) continue;

        final level = await levelService.getLocalLevel(id);
        if (level == null) continue;

        // Delete videos one by one and update size
        for (var (index, sub) in level.sub_levels.indexed) {
          final videoPath = levelService.getFullVideoPath(id, sub.videoFilename);

          final videoFile = File(videoPath);

          if (!await videoFile.exists()) continue;

          final videoSize = await videoFile.length();

          await videoFile.delete();

          // delete full folder if there are no videos left
          if (index == level.sub_levels.length - 1) {
            await compute(_deleteFolderRecursively, folderPath);

            await SharedPref.removeValue(PrefKey.eTag(getLevelJsonPath(id)));
          }

          totalSize -= videoSize;

          if (totalSize < kDeleteCacheThreshold) {
            break;
          }

          // Remove video ETag
          await SharedPref.removeValue(
            PrefKey.eTag(levelService.getVideoPath(id, sub.videoFilename)),
          );

          i++;
        }
      }
    } catch (e) {
      developer.log("Error in cleanup process: $e");
    }
  }

  static Future<void> _deleteFolderRecursively(String path) async {
    final folder = Directory(path);
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  /// Removes least-important cached levels while protecting nearby levels
  Future<void> removeFurthestCachedIds(
    List<String> cachedIds,
    List<String> orderedIds,
    String currentId,
  ) async {
    final Map<String, int> idToIndexMap = {
      for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };

    final int currentIndex = idToIndexMap[currentId] ?? -1;

    cachedIds.sort((idA, idB) {
      final int indexA = idToIndexMap[idA] ?? -1;
      final int indexB = idToIndexMap[idB] ?? -1;

      final int distanceA = indexA - currentIndex;
      final int distanceB = indexB - currentIndex;

      // Keep protected levels at the end
      if (_isProtectedLevel(distanceA)) return 1;
      if (_isProtectedLevel(distanceB)) return -1;

      return distanceA.abs().compareTo(distanceB.abs());
    });

    await cleanLevels(cachedIds);
  }

  /// Prevents deletion of current, previous and next two levels
  bool _isProtectedLevel(int dist) {
    if ((dist < 0 && dist.abs() <= kMaxPreviousLevelsToKeep) || dist <= kMaxNextLevelsToKeep) {
      return true;
    }

    return false;
  }
}

final storageCleanupServiceProvider = Provider<StorageCleanupService>(
  (ref) => StorageCleanupService(ref.read(fileServiceProvider), ref.read(levelServiceProvider)),
);
