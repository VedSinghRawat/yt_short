import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
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

  static Future<void> store(String path, Uint8List data) async {
    final file = File(path);

    await file.parent.create(recursive: true);

    await file.writeAsBytes(data);
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

  static Future<List<String>> listNames(Directory dir, {EntitiesType? type}) async {
    if (!await dir.exists()) {
      throw Exception("Directory does not exist");
    }

    final List<String> entities = [];
    final completer = Completer<List<String>>();

    final stream = dir.list();
    stream.listen(
      (entity) {
        if ((type == EntitiesType.folders && entity is Directory) ||
            (type == EntitiesType.files && entity is File) ||
            (type == null)) {
          entities.add(entity.path.split(Platform.pathSeparator).last);
        }
      },
      onDone: () {
        completer.complete(entities);
      },
      onError: (e) {
        completer.completeError(e);
      },
    );

    return completer.future;
  }

  static Future<Directory?> unzip(File zipFile, Directory destinationDir) async {
    if (!zipFile.existsSync()) return null;

    await destinationDir.create(recursive: true);

    await ZipFile.extractToDirectory(zipFile: zipFile, destinationDir: destinationDir);
    return destinationDir;
  }

  static File getFile(String path, {bool cache = false}) {
    return File('${cache ? cacheDirectory.path : documentsDirectory.path}$path');
  }
}

enum EntitiesType { folders, files }
