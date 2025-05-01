import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_controller.freezed.dart';
part 'sublevel_controller.g.dart';

@freezed
class SublevelControllerState with _$SublevelControllerState {
  const SublevelControllerState._();

  const factory SublevelControllerState({
    Set<SubLevel>? sublevels,
    @Default(false) bool hasFinishedVideo,
    String? error,
  }) = _SublevelControllerState;
}

@Riverpod(keepAlive: true)
class SublevelController extends _$SublevelController {
  late final LevelControllerState levelController = ref.watch(levelControllerProvider);

  @override
  SublevelControllerState build() => const SublevelControllerState();

  void handleDTO(SubLevelDTO dto, String levelId, int index) async {
    final orderedIds = levelController.orderedIds;
    if (orderedIds == null) throw Exception('orderedIds is null');

    final sublevel = SubLevel.fromSubLevelDTO(dto, orderedIds.indexOf(levelId), index, levelId);
    state = state.copyWith(sublevels: state.sublevels == null ? {sublevel} : {...state.sublevels!, sublevel});
  }

  void setVideoPlayingError(String e) => state = state.copyWith(error: e);

  void setHasFinishedVideo(bool to) => state = state.copyWith(hasFinishedVideo: to);
}
