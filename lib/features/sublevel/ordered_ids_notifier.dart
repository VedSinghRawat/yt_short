import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/core/shared_pref.dart';

part 'ordered_ids_notifier.g.dart';

@Riverpod(keepAlive: true)
class OrderedIdsNotifier extends _$OrderedIdsNotifier {
  @override
  AsyncValue<List<String>> build() {
    return const AsyncData([]);
  }

  Future<void> getOrderedIds() async {
    const AsyncValue.loading();

    try {
      final res = await ref.read(levelApiProvider).getOrderedIds();

      state = switch (res) {
        Left(value: final l) => await _handleLeft(l),
        Right(value: final r) => await _handleRight(r),
      };
    } catch (e) {
      state = AsyncValue.error(Failure(message: e.toString()), StackTrace.current);
    }
  }

  Future<AsyncValue<List<String>>> _handleLeft(Failure error) async {
    final localIds = SharedPref.get(PrefKey.orderedIds);

    if (dioConnectionErrors.contains(error.type) && localIds != null) return _getIds();

    return AsyncValue.error(
      Failure(
        message: parseError(error.type!),
        type: error.type,
      ),
      StackTrace.current,
    );
  }

  Future<AsyncValue<List<String>>> _handleRight(List<String>? ids) async {
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
        message: unknownErrorMsg,
      ),
      StackTrace.current,
    );
  }
}
