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

  String getLevelZipPath(String levelId, int zipId) {
    return '$baseZipPath/$levelId/$zipId.zip';
  }

  String get baseZipPath => '${documentsDirectory.path}/levels/zips';

  String getLevelVideoDirPath(String levelId) {
    return '${cacheDirectory.path}/levels/videos/$levelId';
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
    final file = File(getLevelZipPath(levelId, zipId));

    final destinationDir = Directory(getLevelVideoDirPath(levelId));

    return unzip(file, destinationDir);
  }

  Future<void> deleteStoredZip(String levelId, int zipId) async {
    await deleteFile(getLevelZipPath(levelId, zipId));
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);

    await file.delete();
  }

  Future<bool> isZipExists(String levelId, int zipId) async {
    final file = File(getLevelZipPath(levelId, zipId));

    return file.exists();
  }

  Future<bool> isVideoExists(String levelId, String videoId) async {
    final file = File(getUnzippedVideoPath(levelId, videoId));

    return file.exists();
  }

  String getUnzippedVideoPath(String levelId, String videoId) {
    return '${getLevelVideoDirPath(levelId)}/$videoId.mp4';
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
}

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService.instance;
});
