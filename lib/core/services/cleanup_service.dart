import 'dart:developer' as developer show log;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/core/shared_pref.dart';

class StorageCleanupService {
  final LevelService levelService;

  StorageCleanupService(this.levelService);

  /// Main cleanup logic — removes folders from cache if total size exceeds threshold
  Future<void> cleanLevels(List<String> orderedIds) async {
    try {
      Directory targetDir = Directory(PathService.levelsDocDirPath);

      // Ensure directory exists and input is valid
      if (!await targetDir.exists() ||
          orderedIds.isEmpty ||
          orderedIds.length - AppConstants.kProtectedIdsLength == 0) {
        return;
      }

      // Check total size of the cache folder
      int totalSize = await compute(FileService.getDirectorySize, targetDir);

      // No need to clean if under limit
      if (totalSize < AppConstants.kMaxStorageSizeBytes) {
        return;
      }

      int i = 0;

      final toBeDeletedVideoPaths = List<String>.empty();

      // Start deleting until space is freed
      while (i < orderedIds.length - AppConstants.kProtectedIdsLength) {
        final id = orderedIds[i];
        final folderPath = PathService.levelPath(id);
        final folder = Directory(folderPath);

        if (!await folder.exists()) continue;

        final level = await levelService.getLocalLevel(id);
        if (level == null) continue;

        // Delete videos one by one and update size
        for (var (index, sub) in level.sub_levels.indexed) {
          final videoPath = PathService.videoLocalPath(id, sub.videoFilename);

          final videoFile = File(videoPath);

          if (!await videoFile.exists()) continue;

          final videoSize = await videoFile.length();

          toBeDeletedVideoPaths.add(videoPath);

          totalSize -= videoSize;

          // delete full folder if there are no videos left
          if (index == level.sub_levels.length - 1) {
            await compute(_deleteFolderRecursively, folderPath);

            await SharedPref.removeValue(PrefKey.eTag(PathService.levelJsonPath(id)));
          }

          if (totalSize < AppConstants.kDeleteCacheThreshold) {
            if (index != level.sub_levels.length - 1) {
              await compute(_deleteVideos, toBeDeletedVideoPaths);
            }

            await Future.wait(
              toBeDeletedVideoPaths.map(
                (videoPath) => SharedPref.removeValue(
                  PrefKey.eTag(
                    PathService.videoPath(id, videoPath.split('/').last.replaceAll('.mp4', '')),
                  ),
                ),
              ),
            );

            break;
          }
        }

        i++;
      }
    } catch (e) {
      developer.log("Error in cleanup process: $e");
    }
  }

  static Future<void> _deleteVideos(List<String> videoPaths) async {
    await Future.wait(videoPaths.map((videoPath) => File(videoPath).delete()));
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
  bool _isProtectedLevel(int dist) =>
      (dist < 0 && dist.abs() <= AppConstants.kMaxPreviousLevelsToKeep) ||
      dist <= AppConstants.kMaxNextLevelsToKeep;
}

final storageCleanupServiceProvider = Provider<StorageCleanupService>(
  (ref) => StorageCleanupService(ref.read(levelServiceProvider)),
);
