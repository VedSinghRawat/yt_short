import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/user/user_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/views/widgets/show_confirmation_dialog.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';

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
}

@Riverpod(keepAlive: true)
class UserController extends _$UserController {
  late final userAPI = ref.watch(userAPIProvider);
  late final langProvider = ref.read(langControllerProvider.notifier);
  late final lang = ref.watch(langControllerProvider);

  @override
  UserControllerState build() => const UserControllerState();

  User userFromDTO(UserDTO userDTO) {
    final orderedIds = ref.read(levelControllerProvider).orderedIds;

    final maxLevelIndex = orderedIds?.indexOf(userDTO.maxLevelId) ?? -1;
    final userMaxLevel = maxLevelIndex != -1 ? maxLevelIndex + 1 : 1;

    final levelIndex = orderedIds?.indexOf(userDTO.levelId) ?? -1;
    final userLevel = levelIndex != -1 ? levelIndex + 1 : 1;

    final user = User.fromUserDTO(userDTO, userLevel, userMaxLevel);

    return user;
  }

  Future<User> updateCurrentUser(User user) async {
    if (user.prefLang != null) {
      langProvider.changeLanguage(user.prefLang!);
    }

    state = state.copyWith(currentUser: user);
    await SharedPref.store(PrefKey.user, user);

    return user;
  }

  Future<void> removeCurrentUser() async {
    state = state.copyWith(currentUser: null);

    await SharedPref.removeValue(PrefKey.user);
  }

  Future<bool> sync(String levelId, int subLevel) async {
    final user = await userAPI.sync(levelId, subLevel);

    await updateCurrentUser(userFromDTO(user));
    state = state.copyWith(syncFailed: false);
    return true;
  }

  Future<void> updatePrefLang(PrefLang newLang) async {
    if (state.currentUser == null) return;

    state = state.copyWith(loading: true);

    final updatedUserDTO = await userAPI.updateProfile(prefLang: newLang);
    await updateCurrentUser(userFromDTO(updatedUserDTO));

    state = state.copyWith(loading: false);
  }

  Future<bool> resetProfile(BuildContext context) async {
    try {
      if (state.loading) return false;

      state = state.copyWith(loading: true);

      final user = state.currentUser;

      if (user == null) {
        return false;
      }

      final confirmed = await showConfirmationDialog(context, question: 'Are you sure you want to reset your profile?');

      if (!confirmed) {
        return false;
      }

      final resetResult = await userAPI.resetProfile(user.email);
      final newUser = userFromDTO(resetResult);

      final progress = Progress(
        level: newUser.level,
        subLevel: newUser.subLevel,
        levelId: newUser.levelId,
        maxLevel: newUser.maxLevel,
        maxSubLevel: newUser.maxSubLevel,
      );

      // Update progress through UI controller
      final uiController = ref.read(uIControllerProvider.notifier);
      await uiController.storeProgress(progress, userEmail: newUser.email);

      await updateCurrentUser(newUser);

      return true;
    } catch (e) {
      if (!context.mounted) return false;

      showSnackBar(context, message: e.toString(), type: SnackBarType.error);

      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}
