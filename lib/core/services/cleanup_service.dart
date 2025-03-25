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

  Future<List<String>> cleanLevels(List<String> orderedIds) async {
    try {
      Directory targetDir = Directory(fileService.levelsDocDirPath);

      // Ensure directory exists
      if (!await targetDir.exists() || orderedIds.isEmpty) {
        return orderedIds;
      }

      double totalSizeMB = await checkStorageSize(targetDir);

      developer.log('clean levels total size is $totalSizeMB');

      if (totalSizeMB < kMaxStorageSizeMB) {
        return orderedIds;
      }

      // Delete folders until size is under MAX_SIZE_MB
      List<String> remainingIds = orderedIds;

      while (totalSizeMB > kDeleteCacheThresholdMB && remainingIds.isNotEmpty) {
        final id = remainingIds.removeAt(0);

        String folderPath = fileService.getLevelPath(id);

        Directory folder = Directory(folderPath);

        if (!await folder.exists()) continue;

        final folderSize = await checkStorageSize(folder);

        developer.log('folder size is  $folderSize folder is $folder');
        await folder.delete(recursive: true);
        await SharedPref.deleteLevelDTO(id);

        final zips = await fileService.listEntities(folder, type: EntitiesType.folders);

        developer.log('zips folders is  $zips');

        for (var e in zips) {
          await SharedPref.removeEtag('$id$e');
        }

        totalSizeMB = totalSizeMB - folderSize;
      }

      developer.log('$remainingIds');

      return remainingIds;
    } catch (e) {
      developer.log("Error in cleanup process: $e");
      return orderedIds;
    }
  }

  Future<double> checkStorageSize(Directory targetDir) async {
    final totalSize = await compute(fileService.getDirectorySize, targetDir);

    return totalSize / (1024 * 1024);
  }

  Future<List<String>> removeFurthestCachedIds(
    List<String> cachedIds,
    List<String> orderedIds,
    String currentId,
  ) async {
    // Step 1: Build an index lookup for faster access
    final Map<String, int> indexLookup = {
      for (int i = 0; i < orderedIds.length; i++) orderedIds[i]: i
    };

    // Step 2: Get currentId index once
    final int currentIndex = indexLookup[currentId] ?? -1;
    if (currentIndex == -1) return cachedIds; // Edge case: If currentId is not found

    final List<String> protected = [];

    // Step 3: Sort based on distance from currentIndex
    cachedIds.sort((a, b) {
      final int aI = indexLookup[a] ?? -1;
      final int bI = indexLookup[b] ?? -1;

      final int distA = (aI - currentIndex).abs();
      final int distB = (bI - currentIndex).abs();

      if (_isProtectedLevel(currentIndex, aI)) protected.add(a);
      if (_isProtectedLevel(currentIndex, bI)) protected.add(b);

      return distA.compareTo(distB);
    });

    // Step 4: Remove protected items
    cachedIds.removeWhere(protected.contains);

    developer.log('removed protected ids now ids is $cachedIds');

    // Step 5: Clean remaining IDs asynchronously
    final List<String> remainingIds = await compute(cleanLevels, cachedIds);

    return [...protected, ...remainingIds];
  }

  bool _isProtectedLevel(int currIndex, int idIndex) =>
      const {-1, 0, 1, 2}.contains(idIndex - currIndex);
}

final storageCleanupServiceProvider = Provider<StorageCleanupService>((ref) {
  return StorageCleanupService(ref.read(fileServiceProvider));
});
