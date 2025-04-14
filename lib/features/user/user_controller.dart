import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/apis/user_api.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/sublevel/ordered_ids_notifier.dart';
import 'package:myapp/models/models.dart';
import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_controller.freezed.dart';
part 'user_controller.g.dart';

@freezed
class UserControllerState with _$UserControllerState {
  const factory UserControllerState({
    @Default(false) bool loading,
    UserModel? currentUser,
  }) = _UserControllerState;

  const UserControllerState._();

  int get level {
    final progress = SharedPref.get(
      PrefKey.currProgress(userEmail: currentUser?.email),
    );
    return progress?.level ?? currentUser?.level ?? 1;
  }

  int get subLevel {
    final progress = SharedPref.get(
      PrefKey.currProgress(userEmail: currentUser?.email),
    );
    return progress?.subLevel ?? currentUser?.subLevel ?? 1;
  }

  String? get levelId {
    final progress = SharedPref.get(
      PrefKey.currProgress(userEmail: currentUser?.email),
    );
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
    final orderedIds = ref.read(orderedIdsNotifierProvider).value;

    final maxLevelIndex = orderedIds?.indexOf(userDTO.maxLevelId) ?? -1;
    final userMaxLevel = maxLevelIndex != -1 ? maxLevelIndex + 1 : 1;

    final levelIndex = orderedIds?.indexOf(userDTO.levelId) ?? -1;
    final userLevel = levelIndex != -1 ? levelIndex + 1 : 1;

    final user = UserModel.fromUserDTO(userDTO, userLevel, userMaxLevel);

    state = state.copyWith(currentUser: user);

    return user;
  }

  void removeCurrentUser() {
    state = state.copyWith(currentUser: null);

    SharedPref.removeValue(PrefKey.lastLoggedInEmail);
  }

  Future<bool> sync(String levelId, int subLevel) async {
    try {
      final userEither = await _userAPI.sync(levelId, subLevel);

      return userEither.match((l) => false, (r) {
        updateCurrentUser(r);
        return true;
      });
    } catch (e, stack) {
      developer.log('Error in sync', error: e, stackTrace: stack);
      return false;
    }
  }
}
