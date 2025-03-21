import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/level_api.dart';
import 'package:myapp/core/shared_pref.dart';

part 'ordered_ids_notifier.g.dart';

const kOrderedIdETagId = 'ahfafdlkfsdfs'; //some random id

@Riverpod(keepAlive: true)
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
        Left(value: final l) => await _handleLeft(l),
        Right(value: final r) => await _handleRight(r),
      };
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<AsyncValue<List<String>>> _handleLeft(Failure error) async {
    final localIds = await SharedPref.getOrderedIds();

    if (dioConnectionErrors.contains(error.type) && localIds == null) {
      return AsyncValue.error(
        'No internet connection. Please check your connection and try again.',
        StackTrace.current,
      );
    }

    return _getIds();
  }

  Future<AsyncValue<List<String>>> _handleRight(List<String>? ids) async {
    if (ids != null) {
      SharedPref.setOrderedIds(ids);
      return AsyncValue.data(ids);
    }

    return _getIds();
  }

  Future<AsyncValue<List<String>>> _getIds() async {
    final ids = await SharedPref.getOrderedIds();

    if (ids == null) {
      return AsyncValue.error(genericErrorMessage, StackTrace.current);
    }

    return AsyncValue.data(ids);
  }
}
