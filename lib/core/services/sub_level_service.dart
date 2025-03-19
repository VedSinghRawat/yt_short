import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sub_level_api.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/shared_pref.dart';

class SubLevelService {
  final FileService fileService;

  SubLevelService(this.subLevelAPI, this.fileService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getZipFiles(
    String levelId,
    Set<int> zipNumbers,
  ) async {
    // First fetch all zip files in parallel
    await Future.wait(zipNumbers.map((zipNumber) => getZip(levelId, zipNumber)));

    // Then extract all zips in parallel
    await Future.wait(
        zipNumbers.map((zipNumber) => fileService.extrectStoredZip(levelId, zipNumber)));
  }

  Future<String?> getSubLevelFile(String levelId, int zipNumber) async {
    await getZip(levelId, zipNumber);

    final unzipDir = await fileService.extrectStoredZip(levelId, zipNumber);

    return unzipDir?.path;
  }

  Future<String?> getZip(String levelId, int zipNumber) async {
    final eTagKey = '$levelId$zipNumber';

    final eTag = await SharedPref.getETag(eTagKey);

    final zipDataEither = await subLevelAPI.getZipData(levelId, zipNumber, eTag: eTag);

    final zipData = zipDataEither.getRight().toNullable();

    if (zipDataEither.isLeft() || zipData == null) {
      return fileService.getZipPath(levelId, zipNumber);
    }

    await SharedPref.storeETag(levelId, eTagKey);

    final file = File(fileService.getZipPath(levelId, zipNumber));

    await Directory(file.parent.path).create(recursive: true);

    await file.writeAsBytes(zipData.zipFile);

    return file.path;
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final fileService = ref.watch(fileServiceProvider);

  return SubLevelService(subLevelAPI, fileService);
});
