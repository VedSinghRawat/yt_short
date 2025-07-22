import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level/level_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_service.g.dart';

class LevelService {
  final ILevelApi levelApi;
  final PrefLang lang;

  LevelService(this.levelApi, this.lang);

  Future<bool> videoExists(String levelId, String id) async {
    final file = FileService.getFile(PathService.sublevelAsset(levelId, id, AssetType.video));
    return file.exists();
  }

  Future<LevelDTO?> getLocalLevel(String levelId) async {
    final file = FileService.getFile(PathService.levelJson(levelId));

    if (!await file.exists()) return null;

    final content = await file.readAsString();

    final jsonMap = jsonDecode(content) as Map<String, dynamic>;

    return LevelDTO.fromJson(jsonMap);
  }

  FutureEither<LevelDTO> getLevel(String id) async {
    try {
      final level = await levelApi.get(id);

      if (level != null) {
        final file = FileService.getFile(PathService.levelJson(level.id));
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(level.toJson()));

        return right(level);
      }

      final localLevel = await getLocalLevel(id);

      if (localLevel == null) {
        return left(APIError(message: 'Level not found', trace: StackTrace.current));
      }

      return right(localLevel);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }

  FutureEither<List<String>?> getOrderedIds() async {
    try {
      final result = await levelApi.getOrderedIds();
      return right(result); // Can be null for 304 Not Modified responses
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }
}

@riverpod
LevelService levelService(Ref ref) {
  final levelApi = ref.read(levelApiProvider);
  final lang = ref.read(langControllerProvider);
  return LevelService(levelApi, lang);
}
