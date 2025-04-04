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

  Future<int> get level async {
    final progress = await SharedPref.getValue(PrefKey.currProgress);
    return progress?.level ?? currentUser?.level ?? 1;
  }

  Future<int> get subLevel async {
    final progress = await SharedPref.getValue(PrefKey.currProgress);
    return progress?.subLevel ?? currentUser?.subLevel ?? 1;
  }

  Future<String?> get levelId async {
    final progress = await SharedPref.getValue(PrefKey.currProgress);
    return progress?.levelId ?? currentUser?.levelId;
  }
}

@riverpod
class UserController extends _$UserController {
  late final IUserAPI _userAPI;

  @override
  UserControllerState build() {
    _userAPI = ref.watch(userAPIProvider);
    return const UserControllerState();
  }

  Future<UserModel?> getCurrentUser() async {
    state = state.copyWith(loading: true);

    try {
      final authToken = await SharedPref.getValue(PrefKey.googleIdToken);
      if (authToken == null) return null;

      final userDTO = await _userAPI.getUser();
      if (userDTO == null) return null;

      return updateCurrentUser(userDTO);
    } catch (e, stack) {
      developer.log('Error in getCurrentUser', error: e, stackTrace: stack);
      return null;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  UserModel updateCurrentUser(UserDTO userDTO) {
    final orderedIds = ref.read(orderedIdsNotifierProvider).value;
    final userMaxLevel = (orderedIds?.indexOf(userDTO.maxLevelId) ?? 0) + 1;
    final userLevel = (orderedIds?.indexOf(userDTO.levelId) ?? 0) + 1;

    final user = UserModel.fromUserDTO(userDTO, userLevel, userMaxLevel);
    state = state.copyWith(currentUser: user);
    return user;
  }

  void removeCurrentUser() {
    state = state.copyWith(currentUser: null);
  }

  Future<void> sync(String levelId, int subLevel) async {
    try {
      final user = await _userAPI.sync(levelId, subLevel);
      if (user != null) {
        updateCurrentUser(user);
      }
    } catch (e, stack) {
      developer.log('Error in sync', error: e, stackTrace: stack);
    }
  }
}
