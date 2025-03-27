import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
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

    // Then extract all zips in parallel and handle failures
    await Future.wait(
      zipNumbers.map((zipNumber) async {
        final unzipDir = await fileService.extrectStoredZip(levelId, zipNumber);

        if (unzipDir == null) {
          await SharedPref.removeEtag('$levelId$zipNumber');
        }

        return unzipDir;
      }),
    );
  }

  Future<String?> getSubLevelFile(String levelId, int zipNumber) async {
    await getZip(levelId, zipNumber);

    final unzipDir = await fileService.extrectStoredZip(levelId, zipNumber);

    if (unzipDir == null) {
      SharedPref.removeEtag('$levelId$zipNumber');
    }

    return unzipDir?.path;
  }

  Future<String?> getZip(String levelId, int zipNumber) async {
    final eTagKey = '$levelId$zipNumber';

    final zipDataEither = await subLevelAPI.getZipData(levelId, zipNumber, eTagKey);

    return switch (zipDataEither) {
      Left() => _getExistingZipPath(levelId, zipNumber),
      Right(value: final zipData) when zipData == null => _getExistingZipPath(levelId, zipNumber),
      Right(value: final zipData) => _storeZipFile(levelId, zipNumber, zipData!),
    };
  }

  String _getExistingZipPath(String levelId, int zipNumber) {
    return fileService.getZipPath(levelId, zipNumber);
  }

  Future<String> _storeZipFile(String levelId, int zipNumber, List<int> zipData) async {
    final file = File(fileService.getZipPath(levelId, zipNumber));
    await Directory(file.parent.path).create(recursive: true);
    await file.writeAsBytes(zipData);
    return file.path;
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final fileService = ref.watch(fileServiceProvider);

  return SubLevelService(subLevelAPI, fileService);
});
