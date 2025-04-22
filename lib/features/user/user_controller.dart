import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/user_api.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/features/sublevel/level_controller.dart';
import 'package:myapp/models/models.dart';
import 'dart:developer' as developer;
import 'package:myapp/models/user/user.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_controller.freezed.dart';
part 'user_controller.g.dart';

@freezed
class UserControllerState with _$UserControllerState {
  const factory UserControllerState({@Default(false) bool loading, UserModel? currentUser}) =
      _UserControllerState;

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
  late final IUserAPI _userAPI;

  @override
  UserControllerState build() {
    _userAPI = ref.watch(userAPIProvider);
    return const UserControllerState();
  }

  UserModel updateCurrentUser(UserDTO userDTO) {
    final orderedIds = ref.read(levelControllerProvider).value;

    final maxLevelIndex = orderedIds?.indexOf(userDTO.maxLevelId) ?? -1;
    final userMaxLevel = maxLevelIndex != -1 ? maxLevelIndex + 1 : 1;

    final levelIndex = orderedIds?.indexOf(userDTO.levelId) ?? -1;
    final userLevel = levelIndex != -1 ? levelIndex + 1 : 1;

    final user = UserModel.fromUserDTO(userDTO, userLevel, userMaxLevel);

    ref.read(langProvider.notifier).changeLanguage(user.prefLang);

    state = state.copyWith(currentUser: user);

    return user;
  }

  void removeCurrentUser() {
    state = state.copyWith(currentUser: null);

    SharedPref.removeValue(PrefKey.user);
  }

  Future<bool> sync(String levelId, int subLevel) async {
    try {
      final user = await _userAPI.sync(levelId, subLevel);

      updateCurrentUser(user);
      return true;
    } catch (e, stack) {
      developer.log('Error in sync', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> updatePrefLang(PrefLang newLang) async {
    if (state.currentUser == null) return false;

    state = state.copyWith(loading: true);
    try {
      final updatedUserDTO = await _userAPI.updateProfile(prefLang: newLang);
      updateCurrentUser(updatedUserDTO);
      state = state.copyWith(loading: false);
      return true;
    } catch (e, stack) {
      developer.log('Error updating prefLang', error: e, stackTrace: stack);
      state = state.copyWith(loading: false);
      return false;
    }
  }
}
