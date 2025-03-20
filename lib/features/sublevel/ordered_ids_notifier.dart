import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/core/shared_pref.dart';

part 'ordered_ids_notifier.g.dart';

const kOrderedIdETagId = 'ahfafdlkfsdfs'; //some random id

class OrderedIdsNotifier extends _$OrderedIdsNotifier {
  @override
  AsyncValue<List<String>> build() {
    return const AsyncData([]);
  }

  Future<void> getOrderedIds() async {
    const AsyncValue.loading();

    try {
      final eTag = await SharedPref.getETag(kOrderedIdETagId);
      final res = await ref.read(levelApiProvider).getOrderedIds(eTag);

      state = switch (res) {
        Left(value: final l) => AsyncValue.error(l, StackTrace.current),
        Right(value: final r) => await _getIds(r),
      };
    } catch (e) {
      AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<AsyncValue<List<String>>> _getIds(List<String>? right) async {
    if (right != null) return AsyncValue.data(right);

    final ids = await SharedPref.getOrderedIds();

    if (ids == null) {
      return AsyncValue.error('No ids found localy', StackTrace.current);
    }

    return AsyncValue.data(ids);
  }
}
