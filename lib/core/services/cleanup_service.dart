import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/Level/level.dart';

class StorageCleanupService {
  final FileService fileService;

  StorageCleanupService(this.fileService);

  Future<void> cleanUpStorage(List<String> folderList) async {
    try {
      // Get base zip path from FileService
      String baseZipPath = fileService.baseZipPath;

      Directory targetDir = Directory(baseZipPath);

      // Ensure directory exists
      if (!await targetDir.exists()) {
        return;
      }

      // Get folder names inside target directory
      List<String> existingFolders = targetDir
          .listSync()
          .whereType<Directory>()
          .map((dir) => dir.path.split('/').last)
          .toList();

      // Get total size of target directory
      int totalSize = await compute(fileService.getDirectorySize, targetDir);

      double totalSizeMB = totalSize / (1024 * 1024);

      if (totalSizeMB < kMaxStorageSizeMB) {
        return;
      }

      // Delete folders until size is under MAX_SIZE_MB
      int index = 0;
      while (totalSizeMB > kMaxStorageSizeMB && index < folderList.length) {
        String folderName = folderList[index];
        String folderPath = '$baseZipPath/$folderName';
        Directory folder = Directory(folderPath);

        if (await folder.exists()) {
          await folder.delete(recursive: true);

          totalSize = await compute(fileService.getDirectorySize, targetDir);

          totalSizeMB = totalSize / (1024 * 1024);
        }

        index++;
      }

      print("Final Directory Size: ${totalSizeMB.toStringAsFixed(2)} MB");
    } catch (e) {
      print("Error in cleanup process: $e");
    }
  }

  // TODO working here have to improw it
  Future<void> cleanUpCachedLevels() async {
    final cachedLevels = await SharedPref.getCachedLevels();
    final currProgress = await SharedPref.getCurrProgress();

    if (cachedLevels.isEmpty || currProgress == null) return;

    // Create a map for quick lookups
    final Map<String, Level> levelMap = {for (var level in cachedLevels) level.id: level};

    final String? currentLevelId = currProgress.levelId;
    if (currentLevelId == null || !levelMap.containsKey(currentLevelId)) return;

    List<String> orderedLevelIds = [];
    String? prevId = levelMap[currentLevelId]?.prevId;
    String? nextId = levelMap[currentLevelId]?.nextId;

    // Single loop to traverse both previous and next levels
    while (prevId != null || nextId != null) {
      if (prevId != null && levelMap.containsKey(prevId)) {
        orderedLevelIds.insert(0, prevId); // Insert at the beginning
        prevId = levelMap[prevId]?.prevId;
      } else {
        prevId = null; // Stop if no more previous levels
      }

      if (nextId != null && levelMap.containsKey(nextId)) {
        orderedLevelIds.add(nextId); // Append to the end
        nextId = levelMap[nextId]?.nextId;
      } else {
        nextId = null; // Stop if no more next levels
      }
    }

    await cleanUpStorage(orderedLevelIds);
  }
}
