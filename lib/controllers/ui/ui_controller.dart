import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/sublevel/sublevel.dart';

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
    // retain previous progress if needed in future
    await SharedPref.store(PrefKey.currProgress(userEmail: userEmail), progress);
    state = state.copyWith(currentProgress: progress);
  }

  Future<void> removeProgress({String? userEmail}) async {
    await SharedPref.removeValue(PrefKey.currProgress(userEmail: userEmail));
    state = state.copyWith(currentProgress: null);
  }

  Future<void> loadProgressForUser(String userEmail) async {
    final progress = SharedPref.get(PrefKey.currProgress(userEmail: userEmail));
    state = state.copyWith(currentProgress: progress);
  }

  // Enum-based helpers
  String? _exerciseKeyFor(SubLevelType type) {
    switch (type) {
      case SubLevelType.speech:
        return 'speech';
      case SubLevelType.fill:
        return 'fill';
      case SubLevelType.arrange:
        return 'arrange';
      case SubLevelType.video:
        return null; // not tracked for video
    }
  }

  bool getExerciseSeen(SubLevelType type, {String? userEmail}) {
    final key = _exerciseKeyFor(type);
    if (key == null) return true; // ignore video
    final map = SharedPref.get(PrefKey.exercisesSeen(userEmail: userEmail)) ?? <String, bool>{};
    return map[key] == true;
  }

  Future<void> setExerciseSeen(SubLevelType type, {String? userEmail}) async {
    final key = _exerciseKeyFor(type);
    if (key == null) return; // ignore video
    final existing = SharedPref.get(PrefKey.exercisesSeen(userEmail: userEmail)) ?? <String, bool>{};
    final updated = Map<String, bool>.from(existing);
    updated[key] = true;
    await SharedPref.store(PrefKey.exercisesSeen(userEmail: userEmail), updated);
  }
}
