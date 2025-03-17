import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/sub_level_api.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';

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
    Console.timeStart('getSubLevelFile');
    await getZip(levelId, zipNumber);
    Console.timeEnd('getSubLevelFile');

    Console.timeStart('extrectStoredZip');
    final unzipDir = await fileService.extrectStoredZip(levelId, zipNumber);
    Console.timeEnd('extrectStoredZip');

    return unzipDir?.path;
  }

  Future<String?> getZip(String levelId, int zipNumber) async {
    final eTag = await SharedPref.getETag(levelId, zipNumber);

    final zipDataEither = await subLevelAPI.getZipData(levelId, zipNumber, eTag: eTag);

    final zipData = zipDataEither.getRight().toNullable();

    if (zipDataEither.isLeft() || zipData == null) {
      return fileService.getLevelZipPath(levelId, zipNumber);
    }

    await SharedPref.storeETag(levelId, zipNumber, zipData.eTag);

    final file = File(fileService.getLevelZipPath(levelId, zipNumber));

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
