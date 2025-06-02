import 'dart:math' as Math;

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/dialogue/dialogue_controller.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/sublevel/sublevel.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/apis/level/level_api.dart';

part 'level_controller.freezed.dart';
part 'level_controller.g.dart';

@freezed
class LevelControllerState with _$LevelControllerState {
  const LevelControllerState._();

  const factory LevelControllerState({
    List<String>? orderedIds,
    // true when loading, false when loaded, null when not tried to load/fetch
    @Default({}) Map<String, bool> loadingByLevelId,
    String? error,
  }) = _LevelControllerState;
}

@Riverpod(keepAlive: true)
class LevelController extends _$LevelController {
  late final levelService = ref.watch(levelServiceProvider);
  late final langController = ref.watch(langControllerProvider);
  late final subLevelController = ref.watch(sublevelControllerProvider.notifier);
  late final dialogueController = ref.watch(dialogueControllerProvider.notifier);
  late final userController = ref.watch(userControllerProvider);

  @override
  LevelControllerState build() => const LevelControllerState();

  Future<void> getLevel(String id) async {
    state = state.copyWith(
      loadingByLevelId: {...state.loadingByLevelId}..update(id, (value) => true, ifAbsent: () => true),
    );

    final levelDTOEither = await levelService.getLevel(id, ref);
    List<SubLevelDTO> sublevelDTOs = [];
    Set<String> dialogueIds = {};

    final level = levelDTOEither.fold(
      (l) {
        state = state.copyWith(error: l.message);
        return null;
      },
      (r) {
        final level = Level.fromLevelDTO(r);
        int i = 1;
        sublevelDTOs = r.sub_levels;
        r.sub_levels.map((subLevelDTO) {
          subLevelController.set(subLevelDTO, level.id, i++);
          dialogueIds.addAll(subLevelDTO.dialogues.map((d) => d.id));
        });

        return level;
      },
    );

    state = state.copyWith(loadingByLevelId: {...state.loadingByLevelId}..update(id, (value) => false));

    if (level == null) return;

    await Future.wait([
      ...dialogueIds.map((dialogueId) async {
        final dialogue = await dialogueController.get(dialogueId);
        if (dialogue == null) return;
        await dialogueController.downloadData(dialogue.zipNum);
      }),
      ...sublevelDTOs.map((subLevelDTO) => subLevelController.downloadData(subLevelDTO, level.id)),
    ]);
  }

  Future<void> getOrderedIds() async {
    List<String>? res;

    try {
      res = await ref.read(levelApiProvider).getOrderedIds();
      if (res != null) {
        await SharedPref.store(PrefKey.orderedIds, res);
      } else {
        res = SharedPref.get(PrefKey.orderedIds);
      }
    } on DioException catch (e) {
      state = state.copyWith(error: parseError(e.type, ref.read(langControllerProvider)));
    }

    state = state.copyWith(orderedIds: res);
  }

  Future<void> fetchLevels() async {
    final orderedIds = ref.read(levelControllerProvider.notifier).state.orderedIds;

    if (orderedIds == null) {
      state = state.copyWith(error: parseError(DioExceptionType.unknown, ref.read(langControllerProvider)));
      return;
    }

    state = state.copyWith(error: null);
    final user = ref.read(userControllerProvider);
    String currUserLevelId = user.levelId ?? orderedIds.first;

    final loading = state.loadingByLevelId;
    if (loading[currUserLevelId] == null) {
      await getLevel(currUserLevelId);
    }

    final surroundingLevelIds = _getSurroundingLevelIds(orderedIds.indexOf(currUserLevelId), orderedIds);

    final fetchLevelReqs =
        surroundingLevelIds
            .map((levelId) => loading[levelId] == null ? getLevel(levelId) : Future.value(null))
            .toList();

    await Future.wait(fetchLevelReqs);

    if (currUserLevelId == orderedIds.last) {
      final message = AppConstants.allLevelsCompleted(ref.read(langControllerProvider));

      state = state.copyWith(error: message);
    }
  }

  List<String> _getSurroundingLevelIds(int currIndex, List<String?> orderedIds) {
    final startBefore = Math.max(0, currIndex - AppConstants.kMaxBeforeLevels);
    final endAfter = Math.min(orderedIds.length, currIndex + AppConstants.kMaxAfterLevels + 1);
    final startAfter = Math.min(orderedIds.length, currIndex + 1);

    return orderedIds
        .sublist(startBefore, currIndex)
        .followedBy(orderedIds.sublist(startAfter, endAfter))
        .whereType<String>()
        .toList();
  }
}
