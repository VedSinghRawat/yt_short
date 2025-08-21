import 'dart:developer' as developer;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/services/user/user_service.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:fpdart/fpdart.dart';

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
  late final userService = ref.read(userServiceProvider);

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
      final langProvider = ref.read(langControllerProvider.notifier);
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

  Future<APIError?> sync(String levelId, int subLevel) async {
    final result = await userService.sync(levelId, subLevel);

    return result.fold(
      (error) {
        developer.log('Error syncing user progress: ${error.message}', error: error.trace);
        state = state.copyWith(syncFailed: true);
        return error;
      },
      (userDTO) async {
        await updateCurrentUser(userFromDTO(userDTO));
        state = state.copyWith(syncFailed: false);
        return null; // Success
      },
    );
  }

  FutureEither<void> updatePrefLang(PrefLang newLang) async {
    if (state.currentUser == null) return left(APIError(message: 'No user found', trace: StackTrace.current));

    state = state.copyWith(loading: true);

    final result = await userService.updateProfile(prefLang: newLang);

    return result.fold(
      (error) {
        developer.log('Error updating user preference language: ${error.message}', error: error.trace);
        state = state.copyWith(loading: false);
        return left(error);
      },
      (updatedUserDTO) async {
        await updateCurrentUser(userFromDTO(updatedUserDTO));
        state = state.copyWith(loading: false);
        return right(null);
      },
    );
  }

  Future<APIError?> resetProfile() async {
    try {
      if (state.loading) return APIError(message: 'Already processing', trace: StackTrace.current);

      state = state.copyWith(loading: true);

      final user = state.currentUser;

      if (user == null) {
        return APIError(message: 'No user found', trace: StackTrace.current);
      }

      final resetResult = await userService.resetProfile(user.email);

      final foldResult = await resetResult.fold<Future<APIError?>>(
        (error) async {
          developer.log('Error resetting user profile: ${error.message}', error: error.trace);
          return error;
        },
        (userDTO) async {
          final newUser = userFromDTO(userDTO);
          final progress = Progress(
            level: newUser.level,
            subLevel: newUser.subLevel,
            levelId: newUser.levelId,
            maxLevel: newUser.maxLevel,
            maxSubLevel: newUser.maxSubLevel,
            modified: DateTime.parse(newUser.modified).millisecondsSinceEpoch,
          );

          // Update progress through UI controller
          final uiController = ref.read(uIControllerProvider.notifier);
          await uiController.storeProgress(progress, userEmail: newUser.email);

          await updateCurrentUser(newUser);

          return null; // Success
        },
      );

      return foldResult;
    } catch (e) {
      return APIError(message: e.toString(), trace: StackTrace.current);
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  User? getUser() {
    final user = state.currentUser;
    if (user == null) {
      return SharedPref.get(PrefKey.user);
    }
    return user;
  }
}
