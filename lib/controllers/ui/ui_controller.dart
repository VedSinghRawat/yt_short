import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ui_controller.freezed.dart';
part 'ui_controller.g.dart';

@freezed
class UIControllerState with _$UIControllerState {
  const UIControllerState._();

  const factory UIControllerState({@Default(true) bool isAppBarVisible}) = _UIControllerState;
}

@Riverpod(keepAlive: true)
class UIController extends _$UIController {
  @override
  UIControllerState build() => const UIControllerState();

  void setIsAppBarVisible(bool visible) => state = state.copyWith(isAppBarVisible: visible);
}
