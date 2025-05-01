import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/services/level/level_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/core/shared_pref.dart';

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

  @override
  LevelControllerState build() => const LevelControllerState();

  Future<Level?> getLevel(String id) async {
    final levelDTOEither = await levelService.getLevel(id, ref);

    final levelDTO = levelDTOEither.fold((l) {
      state = state.copyWith(error: parseError(l.type, ref.read(langControllerProvider)));
      return null;
    }, (r) => r);

    if (levelDTO == null) return null;

    return Level.fromLevelDTO(levelDTO);
  }

  Future<void> getOrderedIds() async {
    const AsyncValue.loading();

    try {
      final res = await ref.read(levelApiProvider).getOrderedIds();

      final list = await _handleRes(res);

      state = state.copyWith(orderedIds: list.value ?? []);
    } on Failure catch (e) {
      final err = await _handleErr(e);
      state = state.copyWith(orderedIds: err.value ?? []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<AsyncValue<List<String>>> _handleErr(Failure error) async {
    final localIds = SharedPref.get(PrefKey.orderedIds);

    if (dioConnectionErrors.contains(error.type) && localIds != null) {
      return _getIds();
    }

    return AsyncValue.error(
      Failure(message: parseError(error.type, ref.read(langControllerProvider)), type: error.type),
      StackTrace.current,
    );
  }

  Future<AsyncValue<List<String>>> _handleRes(List<String>? ids) async {
    if (ids != null) {
      await SharedPref.store(PrefKey.orderedIds, ids);
      return AsyncValue.data(ids);
    }

    return _getIds();
  }

  Future<AsyncValue<List<String>>> _getIds() async {
    final ids = SharedPref.get(PrefKey.orderedIds);

    if (ids != null) return AsyncValue.data(ids);

    await SharedPref.removeValue(PrefKey.orderedIds);

    return AsyncValue.error(
      Failure(
        message: parseError(DioExceptionType.unknown, ref.read(langControllerProvider)),
        type: DioExceptionType.unknown,
      ),
      StackTrace.current,
    );
  }
}
