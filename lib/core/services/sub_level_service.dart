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
    final zipNums = levelDTO.subLevels.map((subLevelDTO) => subLevelDTO.zipNum).toSet();

    // First fetch all zip files in parallel
    await Future.wait(
      zipNums.map(
        (zipNum) => getZip(levelDTO.id, zipNum),
      ),
    );

    // Then extract all zips in parallel and handle failures
    await Future.wait(
      zipNums.map((zipNum) async {
        final unzipDir = await levelService.extractStoredZip(
          levelDTO.id,
          zipNum,
        );

        if (unzipDir == null) {
          await SharedPref.removeRawValue(
            PrefKey.eTagKey(
              getLevelZipPath(
                levelDTO.id,
                zipNum,
              ),
            ),
          );
        }

        return unzipDir;
      }),
    );
  }

  Future<String?> getSubLevelFile(String levelId, int zipNum) async {
    await getZip(levelId, zipNum);

    final unzipDir = await levelService.extractStoredZip(levelId, zipNum);

    if (unzipDir == null) {
      SharedPref.removeRawValue(
        PrefKey.eTagKey(
          getLevelZipPath(
            levelId,
            zipNum,
          ),
        ),
      );
    }

    return unzipDir?.path;
  }

  Future<String?> getZip(String levelId, int zipNum) async {
    final zipDataEither = await subLevelAPI.getZipData(
      levelId,
      zipNum,
    );

    return switch (zipDataEither) {
      Left() => _getExistingZipPath(
          levelId,
          zipNum,
        ),
      Right(
        value: final zipData,
      )
          when zipData == null =>
        _getExistingZipPath(
          levelId,
          zipNum,
        ),
      Right(
        value: final zipData,
      ) =>
        _storeZipFile(
          levelId,
          zipNum,
          zipData!,
        ),
    };
  }

  String _getExistingZipPath(String levelId, int zipNum) {
    return levelService.getZipPath(levelId, zipNum);
  }

  Future<String> _storeZipFile(String levelId, int zipNum, List<int> zipData) async {
    final file = File(levelService.getZipPath(levelId, zipNum));
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
