import 'dart:developer' as developer show log;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/shared_pref.dart';

class StorageCleanupService {
  final FileService fileService;

  StorageCleanupService(this.fileService);

  /// Main cleanup logic — removes folders from cache if total size exceeds threshold
  Future<List<String>> cleanLevels(List<String> orderedIds) async {
    try {
      Directory targetDir = Directory(fileService.levelsDocDirPath);

      // Ensure directory exists and input is valid
      if (!await targetDir.exists() || orderedIds.isEmpty) {
        return orderedIds;
      }

      // Check total size of the cache folder
      double totalSizeMB = await checkStorageSize(targetDir);
      developer.log('clean levels total size is $totalSizeMB');

      // No need to clean if under limit
      if (totalSizeMB < kMaxStorageSizeMB) {
        return orderedIds;
      }

      List<String> remainingIds = List.from(orderedIds);

      // Start deleting until space is freed
      while (totalSizeMB > kDeleteCacheThresholdMB && remainingIds.isNotEmpty) {
        final id = remainingIds.removeAt(0);
        final folderPath = fileService.getLevelPath(id);
        final folder = Directory(folderPath);

        if (!await folder.exists()) continue;

        final folderSize = await checkStorageSize(folder);
        developer.log('folder size is $folderSize for folder $folder');

        // Get inner folders before deletion
        final zips = await compute(listZips, folder);

        // Delete actual files/folders
        await folder.delete(recursive: true);
        await SharedPref.deleteLevelDTO(id);

        for (var e in zips) {
          await SharedPref.removeEtag('$id$e');
        }

        // Update size
        totalSizeMB -= folderSize;
      }

      developer.log('Remaining IDs after cleanup: $remainingIds');
      return remainingIds;
    } catch (e) {
      developer.log("Error in cleanup process: $e");
      return orderedIds;
    }
  }

  Future<List<String>> listZips(Directory folder) =>
      FileService.listEntities(folder, type: EntitiesType.folders);

  Future<double> checkStorageSize(Directory targetDir) async {
    try {
      final totalSize = await compute(FileService.getDirectorySize, targetDir);
      return totalSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      developer.log('Error in checkStorageSize: $e');
      return 0.0;
    }
  }

  /// Removes least-important cached levels while protecting nearby levels
  Future<List<String>> removeFurthestCachedIds(
    List<String> cachedIds,
    List<String> orderedIds,
    String currentId,
  ) async {
    final Map<String, int> indexLookup = {
      for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i
    };

    final int currentIndex = indexLookup[currentId] ?? -1;
    if (currentIndex == -1) return cachedIds;

    final List<String> protected = [];

    cachedIds.sort((a, b) {
      final int aI = indexLookup[a] ?? -1;
      final int bI = indexLookup[b] ?? -1;

      if (_isProtectedLevel(currentIndex, aI)) protected.add(a);
      if (_isProtectedLevel(currentIndex, bI)) protected.add(b);

      final int distA = (aI - currentIndex).abs();
      final int distB = (bI - currentIndex).abs();

      return distA.compareTo(distB);
    });

    cachedIds.removeWhere(protected.contains);

    developer.log('Removed protected IDs, cleaning: $cachedIds');

    final List<String> remainingIds = await cleanLevels(cachedIds);
    return [...protected, ...remainingIds];
  }

  /// Prevents deletion of current, previous and next two levels
  bool _isProtectedLevel(int currIndex, int idIndex) =>
      const {-1, 0, 1, 2}.contains(idIndex - currIndex);
}

final storageCleanupServiceProvider = Provider<StorageCleanupService>((ref) {
  return StorageCleanupService(ref.read(fileServiceProvider));
});
