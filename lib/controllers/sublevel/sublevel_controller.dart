import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/services/sublevel/sublevel_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/error/api_error.dart';

part 'sublevel_controller.freezed.dart';
part 'sublevel_controller.g.dart';

@freezed
class SublevelControllerState with _$SublevelControllerState {
  const SublevelControllerState._();

  const factory SublevelControllerState({Set<SubLevel>? sublevels, @Default(false) bool hasFinishedSublevel}) =
      _SublevelControllerState;
}

@Riverpod(keepAlive: true)
class SublevelController extends _$SublevelController {
  late final subLevelService = ref.read(subLevelServiceProvider);

  @override
  SublevelControllerState build() => const SublevelControllerState();

  void set(SubLevelDTO dto, String levelId, int index, int levelIndex) async {
    final sublevel = SubLevel.fromDTO(dto, levelIndex, index, levelId);
    state = state.copyWith(sublevels: state.sublevels == null ? {sublevel} : {...state.sublevels!, sublevel});
  }

  String getAssetUrl(String levelId, String id, AssetType assetType, BaseUrl baseUrl) {
    return '${baseUrl.url}${PathService.sublevelAsset(levelId, id, assetType)}';
  }

  void setHasFinishedSublevel(bool to) => state = state.copyWith(hasFinishedSublevel: to);

  Future<APIError?> getAssets(SubLevelDTO subLevelDTO, String levelId) async {
    final result = await subLevelService.getAssets(subLevelDTO, levelId);

    final error = result.fold((error) {
      developer.log('Error getting sublevel assets: ${error.message}', error: error.trace);
      return error;
    }, (_) => null);

    return error;
  }
}
