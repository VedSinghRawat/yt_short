import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import '../../apis/user_api.dart';
import '../../models/models.dart';
import 'dart:developer' as developer;

@immutable
class UserControllerState {
  final Map<String, UserModel> users;
  final bool loading;
  final UserModel? currentUser;

  const UserControllerState({
    this.users = const {},
    this.loading = false,
    this.currentUser,
  });

  UserControllerState copyWith({
    Map<String, UserModel>? users,
    bool? loading,
    UserModel? currentUser,
  }) {
    return UserControllerState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class UserController extends StateNotifier<UserControllerState> {
  final IUserAPI userAPI;

  UserController(this.userAPI) : super(const UserControllerState());

  Future<UserModel?> getCurrentUser() async {
    state = state.copyWith(loading: true);

    try {
      final user = await userAPI.getUser();

      if (user == null) return null;

      await updateUser(user);

      updateCurrentUser(user);

      return user;
    } catch (e, stackTrace) {
      developer.log('Error in UserController.getCurrentUser', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);

    return null;
  }

  Future<void> updateUser(UserModel user) async {
    state = state.copyWith(users: {...state.users, user.email: user});
  }

  updateCurrentUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  removeCurrentUser() {
    state = state.copyWith(currentUser: null);
  }

  Future<void> progressSync(int level, int subLevel) async {
    try {
      final user = await userAPI.progressSync(level, subLevel);
      if (user == null) return;

      await updateUser(user);

      await SharedPref.setLastSync(DateTime.now().millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      developer.log('Error in UserController.updateLastViewedVideo', error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final userControllerProvider = StateNotifierProvider<UserController, UserControllerState>((ref) {
  final userAPI = ref.read(userAPIProvider);
  return UserController(userAPI);
});
