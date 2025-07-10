import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/services/sublevel/sublevel_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_controller.freezed.dart';
part 'sublevel_controller.g.dart';

@freezed
class SublevelControllerState with _$SublevelControllerState {
  const SublevelControllerState._();

  const factory SublevelControllerState({
    Set<SubLevel>? sublevels,
    @Default(false) bool hasFinishedSublevel,
    String? error,
  }) = _SublevelControllerState;
}

@Riverpod(keepAlive: true)
class SublevelController extends _$SublevelController {
  late final subLevelService = ref.watch(subLevelServiceProvider);

  @override
  SublevelControllerState build() => const SublevelControllerState();

  void set(SubLevelDTO dto, String levelId, int index, int levelIndex) async {
    final sublevel = SubLevel.fromDTO(dto, levelIndex, index, levelId);
    state = state.copyWith(sublevels: state.sublevels == null ? {sublevel} : {...state.sublevels!, sublevel});
  }

  String getVideoUrl(String levelId, String id, BaseUrl baseUrl) {
    return '${baseUrl.url}${PathService.sublevelAsset(levelId, id, AssetType.video)}';
  }

  void setVideoPlayingError(String e) => state = state.copyWith(error: e);

  void setHasFinishedSublevel(bool to) => state = state.copyWith(hasFinishedSublevel: to);

  Future<void> downloadData(SubLevelDTO subLevelDTO, String levelId) async {
    try {
      await subLevelService.downloadData(subLevelDTO, levelId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to download sublevel data: $e');
    }
  }
}
