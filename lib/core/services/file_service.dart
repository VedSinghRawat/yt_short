import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  static late Directory documentsDirectory;
  static late Directory cacheDirectory;

  FileService._internal();

  static Future<void> init() async {
    documentsDirectory = await getApplicationDocumentsDirectory();
    cacheDirectory = await getApplicationCacheDirectory();
  }

  static Future<void> deleteFile(String path) async {
    final file = File(path);

    await file.delete();
  }

  static int getDirectorySize(Directory directory) {
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

  static Future<List<String>> listEntities(Directory directory, {EntitiesType? type}) async {
    if (!await directory.exists()) {
      throw Exception("Directory does not exist");
    }

    final List<String> entities = [];

    await for (var entity in directory.list()) {
      if ((type == EntitiesType.folders && entity is Directory) ||
          (type == EntitiesType.files && entity is File) ||
          (type == null)) {
        entities.add(entity.path.split(Platform.pathSeparator).last);
      }
    }

    return entities;
  }

  static Future<Directory?> unzip(File zipFile, Directory destinationDir) async {
    if (!zipFile.existsSync()) return null;

    await destinationDir.create(recursive: true);

    await ZipFile.extractToDirectory(zipFile: zipFile, destinationDir: destinationDir);
    return destinationDir;
  }
}

enum EntitiesType { folders, files }
