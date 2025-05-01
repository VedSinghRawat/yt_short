import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level/level_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_service.g.dart';

class LevelService {
  final ILevelApi levelApi;
  final LangController langController;

  LevelService(this.levelApi, this.langController);

  Future<bool> videoExists(String levelId, String videoFilename) async {
    final file = File(PathService.videoLocal(levelId, videoFilename));
    return file.exists();
  }

  Future<void> setLocalLevel(LevelDTO level) async {
    final file = File(PathService.levelJsonFull(level.id));

    await file.parent.create(recursive: true);

    await file.writeAsString(jsonEncode(level.toJson()));
  }

  Future<LevelDTO?> getLocalLevel(String levelId) async {
    final file = File(PathService.levelJsonFull(levelId));

    if (!await file.exists()) return null;

    final content = await file.readAsString();

    final jsonMap = jsonDecode(content) as Map<String, dynamic>;

    return LevelDTO.fromJson(jsonMap);
  }

  FutureEither<LevelDTO> getLevel(String id, Ref ref) async {
    final level = await levelApi.get(id);

    if (level != null) {
      await setLocalLevel(level);

      return right(level);
    }

    final localLevel = await getLocalLevel(id);

    if (localLevel == null) {
      return left(
        APIError(
          message: parseError(DioExceptionType.connectionError, ref.read(langControllerProvider)),
          trace: StackTrace.current,
        ),
      );
    }

    return right(localLevel);
  }
}

@riverpod
LevelService levelService(Ref ref) {
  final levelApi = ref.watch(levelApiProvider);
  final langController = ref.watch(langControllerProvider.notifier);
  return LevelService(levelApi, langController);
}
