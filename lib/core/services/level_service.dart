import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/file_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_service.g.dart';

class LevelService {
  final FileService fileService;
  final ILevelApi levelApi;

  LevelService(this.fileService, this.levelApi);

  String get levelsDocDirPath =>
      '${fileService.documentsDirectory.path}/levels';
  String get levelsCacheDirPath => '${fileService.cacheDirectory.path}/levels';

  String getLevelPath(String levelId) {
    return '$levelsDocDirPath/$levelId';
  }

  String getLevelJsonPath(String levelId) {
    return '${fileService.documentsDirectory.path}${getLevelJsonPath(levelId)}';
  }

  String getVideoBasePathEndPoint(String levelId) {
    return '/levels/$levelId/videos';
  }

  String getVideoPathEndPoint(String levelId, String videoFilename) {
    return '${getVideoBasePathEndPoint(levelId)}/$videoFilename.mp4';
  }

  String getVideoDirPath(String levelId) {
    return '${fileService.documentsDirectory.path}${getVideoBasePathEndPoint(levelId)}';
  }

  String getVideoPath(String levelId, String videoFilename) {
    return '${fileService.documentsDirectory.path}${getVideoPathEndPoint(levelId, videoFilename)}';
  }

  Future<bool> doesVideoExists(String levelId, String videoFilename) async {
    final file = File(getVideoPath(levelId, videoFilename));
    return file.exists();
  }

  Future<void> _saveLevel(LevelDTO level) async {
    final file = File(getLevelJsonPath(level.id));

    await file.parent.create(recursive: true);

    await file.writeAsString(jsonEncode(level.toJson()));
  }

  Future<LevelDTO?> getLocalLevel(String levelId) async {
    final file = File(getLevelJsonPath(levelId));

    if (!await file.exists()) return null;

    final content = await file.readAsString();

    final jsonMap = jsonDecode(content) as Map<String, dynamic>;

    return LevelDTO.fromJson(jsonMap);
  }

  FutureEither<LevelDTO> getLevel(String id) async {
    try {
      final levelEither = await levelApi.get(id);

      return switch (levelEither) {
        Right(value: final r) =>
          r == null
              ? await getLocalLevel(id).then((level) {
                if (level == null) {
                  return left(
                    Failure(
                      message: connectionErrorMsg,
                      trace: StackTrace.current,
                      type: DioExceptionType.connectionError,
                    ),
                  );
                }
                return right(level);
              })
              : _saveLevel(r).then((b) => right(r)),
        Left(value: final l) => left(l),
      };
    } catch (e, st) {
      return left(Failure(message: e.toString(), trace: st));
    }
  }
}

@riverpod
LevelService levelService(Ref ref) {
  final fileService = ref.read(fileServiceProvider);
  final levelApi = ref.read(levelApiProvider);
  return LevelService(fileService, levelApi);
}
