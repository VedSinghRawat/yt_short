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
    return '${documentsDirectory.path}/levels/zips/$levelId/$zipId.zip';
  }

  String getLevelVideoDirPath(String levelId) {
    return '${cacheDirectory.path}/levels/videos/$levelId/';
  }

  Future<Directory?> unzip(Directory zipDir) async {
    final file = File(zipDir.path);

    if (!file.existsSync()) return null;

    await ZipFile.extractToDirectory(
      zipFile: file,
      destinationDir: zipDir,
    );

    return zipDir;
  }

  Future<Directory?> extrectStoredZip(String levelId, int zipId) async {
    final file = File(getLevelZipPath(levelId, zipId));

    return unzip(Directory(file.path));
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
}

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService.instance;
});
