import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_service.g.dart';

class LevelService {
  final ILevelApi levelApi;

  LevelService(this.levelApi);

  Future<bool> videoExists(String levelId, String videoFilename) async {
    final file = File(PathService.videoLocalPath(levelId, videoFilename));
    return file.exists();
  }

  Future<void> _saveLevel(LevelDTO level) async {
    final file = File(PathService.levelJsonFullPath(level.id));

    await file.parent.create(recursive: true);

    await file.writeAsString(jsonEncode(level.toJson()));
  }

  Future<LevelDTO?> getLocalLevel(String levelId) async {
    final file = File(PathService.levelJsonFullPath(levelId));

    if (!await file.exists()) return null;

    final content = await file.readAsString();

    final jsonMap = jsonDecode(content) as Map<String, dynamic>;

    return LevelDTO.fromJson(jsonMap);
  }

  FutureEither<LevelDTO> getLevel(String id) async {
    try {
      final level = await levelApi.get(id);

      if (level != null) {
        await _saveLevel(level);

        return right(level);
      }

      final localLevel = await getLocalLevel(id);

      if (localLevel == null) {
        return left(
          Failure(
            message: AppConstants.connectionErrorMsg,
            trace: StackTrace.current,
            type: DioExceptionType.connectionError,
          ),
        );
      }

      return right(localLevel);
    } catch (e, st) {
      //remove eTag from shared pref
      await SharedPref.removeValue(PrefKey.eTag(PathService.levelJsonPath(id)));

      return left(Failure(message: e.toString(), trace: st));
    }
  }
}

@riverpod
LevelService levelService(Ref ref) {
  final levelApi = ref.read(levelApiProvider);
  return LevelService(levelApi);
}
