import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/sublevel/sublevel_api.dart';
import 'package:myapp/services/file/file_service.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_service.g.dart';

class SubLevelService {
  final LevelService levelService;

  SubLevelService(this.subLevelAPI, this.levelService);

  final ISubLevelAPI subLevelAPI;

  Future<void> getAssets(SubLevelDTO subLevelDTO, String levelId) async {
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
        if (type == AssetType.image) developer.log('storing asset to $path');
        await FileService.store(path, data);
      }
    } catch (e) {
      developer.log(e.toString());
    }
  }
}

@riverpod
SubLevelService subLevelService(Ref ref) {
  final subLevelAPI = ref.watch(subLevelAPIProvider);
  final levelService = ref.watch(levelServiceProvider);
  return SubLevelService(subLevelAPI, levelService);
}
