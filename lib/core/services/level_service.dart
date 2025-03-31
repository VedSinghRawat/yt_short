import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_service.g.dart';

class LevelService {
  final FileService fileService;

  LevelService(this.fileService);

  String get levelsDocDirPath => '${fileService.documentsDirectory.path}/levels';
  String get levelsCacheDirPath => '${fileService.cacheDirectory.path}/levels';

  String getLevelPath(String levelId) {
    return '$levelsDocDirPath/$levelId';
  }

  String getZipPath(String levelId, int zipId) {
    return '${getZipBasePath(levelId)}/$zipId.zip';
  }

  String getZipBasePath(String levelId) {
    return '${getLevelPath(levelId)}/zips';
  }

  String getVideoDirPath(String levelId) {
    return '$levelsCacheDirPath/videos/$levelId';
  }

  String getUnzippedVideoPath(String levelId, String videoId) {
    return '${getVideoDirPath(levelId)}/$videoId.mp4';
  }

  Future<Directory?> extractStoredZip(String levelId, int zipId) async {
    final file = File(getZipPath(levelId, zipId));
    final destinationDir = Directory(getVideoDirPath(levelId));
    return fileService.unzip(file, destinationDir);
  }

  Future<void> deleteStoredZip(String levelId, int zipId) async {
    await fileService.deleteFile(getZipPath(levelId, zipId));
  }

  Future<bool> isZipExists(String levelId, int zipId) async {
    final file = File(getZipPath(levelId, zipId));
    return file.exists();
  }
}

@riverpod
LevelService levelService(Ref ref) {
  final fileService = ref.read(fileServiceProvider);
  return LevelService(fileService);
}
