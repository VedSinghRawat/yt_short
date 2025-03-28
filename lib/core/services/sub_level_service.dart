import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/sub_level_api.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';

class SubLevelService {
  final LevelService levelService;

  SubLevelService(this.subLevelAPI, this.levelService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getZipFiles(
    LevelDTO levelDTO,
  ) async {
    final zipNumbers = levelDTO.subLevels.map((subLevelDTO) => subLevelDTO.zip).toSet();

    // First fetch all zip files in parallel
    await Future.wait(
      zipNumbers.map(
        (zipNumber) => getZip(levelDTO.id, zipNumber),
      ),
    );

    // Then extract all zips in parallel and handle failures
    await Future.wait(
      zipNumbers.map((zipNumber) async {
        final unzipDir = await levelService.extractStoredZip(
          levelDTO.id,
          zipNumber,
        );

        if (unzipDir == null) {
          await SharedPref.removeEtag(
            getLevelZipPath(
              levelDTO.id,
              zipNumber,
            ),
          );
        }

        return unzipDir;
      }),
    );
  }

  Future<String?> getSubLevelFile(String levelId, int zipNumber) async {
    await getZip(levelId, zipNumber);

    final unzipDir = await levelService.extractStoredZip(levelId, zipNumber);

    if (unzipDir == null) {
      SharedPref.removeEtag(
        getLevelZipPath(
          levelId,
          zipNumber,
        ),
      );
    }

    return unzipDir?.path;
  }

  Future<String?> getZip(String levelId, int zipNumber) async {
    final zipDataEither = await subLevelAPI.getZipData(
      levelId,
      zipNumber,
    );

    return switch (zipDataEither) {
      Left() => _getExistingZipPath(
          levelId,
          zipNumber,
        ),
      Right(
        value: final zipData,
      )
          when zipData == null =>
        _getExistingZipPath(
          levelId,
          zipNumber,
        ),
      Right(
        value: final zipData,
      ) =>
        _storeZipFile(
          levelId,
          zipNumber,
          zipData!,
        ),
    };
  }

  String _getExistingZipPath(String levelId, int zipNumber) {
    return levelService.getZipPath(levelId, zipNumber);
  }

  Future<String> _storeZipFile(String levelId, int zipNumber, List<int> zipData) async {
    final file = File(levelService.getZipPath(levelId, zipNumber));
    await Directory(file.parent.path).create(recursive: true);
    await file.writeAsBytes(zipData);
    return file.path;
  }
}

final subLevelServiceProvider = Provider<SubLevelService>((ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);

  return SubLevelService(subLevelAPI, levelService);
});
