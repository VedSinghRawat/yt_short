import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  static final FileService _instance = FileService._internal();

  late Directory documentsDirectory;
  late Directory cacheDirectory;

  FileService._internal();

  Future<void> init() async {
    documentsDirectory = await getApplicationDocumentsDirectory();
    cacheDirectory = await getApplicationCacheDirectory();
  }

  static FileService get instance => _instance;

  String getZipPath(String levelId, int zipId) {
    return '${getLevelPath(levelId)}/$zipId.zip';
  }

  String getLevelPath(String levelId) {
    return '$levelsDocDirPath/$levelId';
  }

  String get levelsDocDirPath => '${documentsDirectory.path}/levels';
  String get levelsCacheDirPath => '${cacheDirectory.path}/levels';

  String getVideoDirPath(String levelId) {
    return '$levelsCacheDirPath/videos/$levelId';
  }

  Future<Directory?> unzip(File zipFile, Directory destinationDir) async {
    if (!zipFile.existsSync()) return null;

    await destinationDir.create(recursive: true);

    await ZipFile.extractToDirectory(
      zipFile: zipFile,
      destinationDir: destinationDir,
    );
    return destinationDir;
  }

  Future<Directory?> extrectStoredZip(String levelId, int zipId) async {
    final file = File(getZipPath(levelId, zipId));

    final destinationDir = Directory(getVideoDirPath(levelId));

    return unzip(file, destinationDir);
  }

  Future<void> deleteStoredZip(String levelId, int zipId) async {
    await deleteFile(getZipPath(levelId, zipId));
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);

    await file.delete();
  }

  Future<bool> isZipExists(String levelId, int zipId) async {
    final file = File(getZipPath(levelId, zipId));

    return file.exists();
  }

  Future<bool> isVideoExists(String levelId, String videoId) async {
    final file = File(getUnzippedVideoPath(levelId, videoId));

    return file.exists();
  }

  String getUnzippedVideoPath(String levelId, String videoId) {
    return '${getVideoDirPath(levelId)}/$videoId.mp4';
  }

  int getDirectorySize(Directory directory) {
    int totalSize = 0;
    try {
      List<FileSystemEntity> files = directory.listSync(recursive: true);

      for (var file in files) {
        if (file is File) {
          totalSize += file.lengthSync();
        }
      }
    } catch (e) {
      developer.log("Error calculating directory size: $e", name: 'FileService');
    }
    return totalSize;
  }

  Future<List<String>> listEntities(Directory directory,
      {EntitiesType type = EntitiesType.both}) async {
    if (!await directory.exists()) {
      throw Exception("Directory does not exist");
    }

    final List<String> entities = [];

    await for (var entity in directory.list()) {
      if ((type == EntitiesType.folders && entity is Directory) ||
          (type == EntitiesType.files && entity is File) ||
          (type == EntitiesType.both)) {
        entities.add(entity.path.split(Platform.pathSeparator).last);
      }
    }

    return entities;
  }
}

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService.instance;
});

enum EntitiesType { folders, files, both }
