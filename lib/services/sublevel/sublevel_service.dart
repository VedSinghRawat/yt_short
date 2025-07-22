import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/sublevel/sublevel_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_service.g.dart';

class SubLevelService {
  final ISubLevelAPI subLevelAPI;
  final LevelService levelService;
  final PrefLang lang;

  SubLevelService(this.subLevelAPI, this.levelService, this.lang);

  FutureEither<void> getAssets(SubLevelDTO subLevelDTO, String levelId) async {
    final assetTypes = {
      AssetType.video: subLevelDTO.isVideo,
      AssetType.audio: subLevelDTO.isSpeechExercise || subLevelDTO.isArrangeExercise,
      AssetType.image: subLevelDTO.isArrangeExercise || subLevelDTO.isFillExercise,
    };

    try {
      for (final type in assetTypes.keys) {
        if (assetTypes[type] == false) continue;

        final data = await subLevelAPI.getAsset(levelId, subLevelDTO.id, type);
        if (data == null) continue;

        final path = PathService.sublevelAsset(levelId, subLevelDTO.id, type);
        await FileService.store(path, data);
      }
      return right(null);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }
}

@riverpod
SubLevelService subLevelService(Ref ref) {
  final subLevelAPI = ref.read(subLevelAPIProvider);
  final levelService = ref.read(levelServiceProvider);
  final lang = ref.read(langControllerProvider);
  return SubLevelService(subLevelAPI, levelService, lang);
}
