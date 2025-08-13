import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/shared_pref.dart';
import 'dart:developer' as developer;

part 'ui_controller.freezed.dart';
part 'ui_controller.g.dart';

@freezed
class UIControllerState with _$UIControllerState {
  const UIControllerState._();

  const factory UIControllerState({@Default(false) bool isAppBarVisible, Progress? currentProgress}) =
      _UIControllerState;
}

@Riverpod(keepAlive: true)
class UIController extends _$UIController {
  @override
  UIControllerState build() {
    final progress = SharedPref.get(PrefKey.currProgress());
    return UIControllerState(currentProgress: progress);
  }

  void setIsAppBarVisible(bool visible) => state = state.copyWith(isAppBarVisible: visible);

  Future<void> storeProgress(Progress progress, {String? userEmail}) async {
    final prev = state.currentProgress;
    await SharedPref.store(PrefKey.currProgress(userEmail: userEmail), progress);
    state = state.copyWith(currentProgress: progress);
    final prevLabel =
        prev == null ? 'null' : 'L${prev.level}-S${prev.subLevel} (max L${prev.maxLevel}-S${prev.maxSubLevel})';
    final newLabel = 'L${progress.level}-S${progress.subLevel} (max L${progress.maxLevel}-S${progress.maxSubLevel})';
    developer.log('[UIController] Progress updated: $prevLabel -> $newLabel | levelId=${progress.levelId}');
  }

  Future<void> removeProgress({String? userEmail}) async {
    await SharedPref.removeValue(PrefKey.currProgress(userEmail: userEmail));
    state = state.copyWith(currentProgress: null);
    developer.log('[UIController] Progress removed');
  }
}
