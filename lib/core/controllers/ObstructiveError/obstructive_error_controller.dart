// State class to track version check state
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'obstructive_error_controller.freezed.dart';
part 'obstructive_error_controller.g.dart';

@freezed
class ObstructiveErrorState with _$ObstructiveErrorState {
  const ObstructiveErrorState._();

  const factory ObstructiveErrorState({String? content, @Default(false) bool closable}) =
      _ObstructiveErrorState;
}

@riverpod
class ObstructiveErrorController extends _$ObstructiveErrorController {
  @override
  ObstructiveErrorState build() => const ObstructiveErrorState();

  void dismissObstructiveError() {
    state = state.copyWith(content: null);
  }
}
