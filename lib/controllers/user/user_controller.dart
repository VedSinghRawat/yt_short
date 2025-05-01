import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/user/user_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/models/user/user.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_controller.freezed.dart';
part 'user_controller.g.dart';

@freezed
class UserControllerState with _$UserControllerState {
  const factory UserControllerState({
    @Default(false) bool loading,
    User? currentUser,
    @Default(false) bool syncFailed,
  }) = _UserControllerState;

  const UserControllerState._();

  Progress? get progress => SharedPref.get(PrefKey.currProgress(userEmail: currentUser?.email));

  int get level {
    return progress?.level ?? currentUser?.level ?? 1;
  }

  int get subLevel {
    return progress?.subLevel ?? currentUser?.subLevel ?? 1;
  }

  String? get levelId {
    return progress?.levelId ?? currentUser?.levelId;
  }
}

@Riverpod(keepAlive: true)
class UserController extends _$UserController {
  late final userAPI = ref.watch(userAPIProvider);
  late final langProvider = ref.read(langControllerProvider.notifier);

  @override
  UserControllerState build() => const UserControllerState();

  User updateCurrentUser(UserDTO userDTO) {
    final orderedIds = ref.read(levelControllerProvider).orderedIds;

    final maxLevelIndex = orderedIds?.indexOf(userDTO.maxLevelId) ?? -1;
    final userMaxLevel = maxLevelIndex != -1 ? maxLevelIndex + 1 : 1;

    final levelIndex = orderedIds?.indexOf(userDTO.levelId) ?? -1;
    final userLevel = levelIndex != -1 ? levelIndex + 1 : 1;

    final user = User.fromUserDTO(userDTO, userLevel, userMaxLevel);

    if (user.prefLang != null) {
      langProvider.changeLanguage(user.prefLang!);
    }

    state = state.copyWith(currentUser: user);

    return user;
  }

  void removeCurrentUser() {
    state = state.copyWith(currentUser: null);

    SharedPref.removeValue(PrefKey.user);
  }

  Future<bool> sync(String levelId, int subLevel) async {
    final user = await userAPI.sync(levelId, subLevel);

    updateCurrentUser(user);
    state = state.copyWith(syncFailed: false);
    return true;
  }

  Future<bool> updatePrefLang(PrefLang newLang) async {
    if (state.currentUser == null) return false;

    state = state.copyWith(loading: true);

    final updatedUserDTO = await userAPI.updateProfile(prefLang: newLang);
    updateCurrentUser(updatedUserDTO);

    state = state.copyWith(loading: false);
    return true;
  }
}
