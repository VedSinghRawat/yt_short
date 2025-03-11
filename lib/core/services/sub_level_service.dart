import 'package:myapp/apis/sub_level_api.dart';
import 'package:myapp/models/sublevel/sublevel_dto.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_archive/flutter_archive.dart';

class SubLevelService {
  SubLevelService(this.subLevelAPI);

  final ISubLevelAPI subLevelAPI;

  Future<String> getCachedZipPath(int zipId) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/levels/$zipId.zip');

    return file.path;
  }

  Future<List<String>> getListSubLevel(List<SubLevelDto> subLevels) async {
    for (var subLevel in subLevels) {
      await getVideoPath(subLevel.zipNumber);
    }

    return subLevels.map((e) => e.id).toList();
  }

  // Future<String> getVideoPath(String zipId, List<SubLevelDto> subLevels) async {
  //   if (await isZipExists(zipId)) {
  //     final localPath = (await unzip(zipId)).path;

  //     final isAllVideoExists =
  //         await Future.wait(subLevels.map((e) => File('$localPath/${e.id}.mp4').exists()))
  //             .then((results) => results.every((exists) => exists));

  //     if (isAllVideoExists) return localPath;
  //   }

  //   return await downloadAndUnzipVideo(zipId);
  // }

  Future<String> getVideoPath(int zipId) async {
    if (await isZipExists(zipId)) {
      final unzipDir = await unzip(zipId);

      return unzipDir.path;
    }

    final zip = await subLevelAPI.getZip(zipId);

    final file = File(await getCachedZipPath(zipId));

    await file.writeAsBytes(zip.codeUnits);

    final unzipDir = await unzip(zipId);

    return unzipDir.path;
  }

  Future<Directory> unzip(int zipId) async {
    final file = File(await getCachedZipPath(zipId));

    final tempDir = await getTemporaryDirectory();

    final tempVideoDir = Directory('${tempDir.path}/$zipId');

    await ZipFile.extractToDirectory(
      zipFile: file,
      destinationDir: tempVideoDir,
    );

    return tempVideoDir;
  }

  Future<void> deleteZip(int zipId) async {
    final file = File(await getCachedZipPath(zipId));

    await file.delete();
  }

  Future<bool> isZipExists(int zipId) async {
    final file = File(await getCachedZipPath(zipId));

    return file.exists();
  }
}
