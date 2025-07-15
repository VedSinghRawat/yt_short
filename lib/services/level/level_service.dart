import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level/level_api.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_service.g.dart';

class LevelService {
  final ILevelApi levelApi;

  LevelService(this.levelApi);

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

  FutureEither<LevelDTO> getLevel(String id, Ref ref) async {
    final level = await levelApi.get(id);

    if (level != null) {
      final file = FileService.getFile(PathService.levelJson(level.id));
      await file.parent.create(recursive: true);
      developer.log('Writing level to file: ${level.toJson()}');
      await file.writeAsString(jsonEncode(level.toJson()));

      return right(level);
    }

    final localLevel = await getLocalLevel(id);

    if (localLevel == null) {
      return left(APIError(message: 'Level not found', trace: StackTrace.current));
    }

    return right(localLevel);
  }
}

@riverpod
LevelService levelService(Ref ref) {
  final levelApi = ref.watch(levelApiProvider);
  return LevelService(levelApi);
}
