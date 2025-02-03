import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/user_api.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/models.dart';
import 'dart:developer' as developer;

@immutable
class UserControllerState {
  final bool loading;
  final UserModel? currentUser;

  const UserControllerState({
    this.loading = false,
    this.currentUser,
  });

  UserControllerState copyWith({
    bool? loading,
    UserModel? currentUser,
  }) {
    return UserControllerState(
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
      final authToken = await SharedPref.getGoogleIdToken();

      if (authToken == null) return null;

      final user = await userAPI.getUser();

      if (user == null) return null;

      await updateCurrentUser(user);

      updateCurrentUser(user);

      return user;
    } catch (e, stackTrace) {
      developer.log('Error in UserController.getCurrentUser',
          error: e.toString(), stackTrace: stackTrace);
    } finally {
      state = state.copyWith(loading: false);
    }

    return null;
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

      await updateCurrentUser(user);
    } catch (e, stackTrace) {
      developer.log('Error in UserController.updateLastViewedVideo',
          error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final userControllerProvider = StateNotifierProvider<UserController, UserControllerState>((ref) {
  final userAPI = ref.watch(userAPIProvider);

  return UserController(userAPI);
});
