import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../apis/user_api.dart';
import '../../models/models.dart';
import '../../core/utils.dart';
import 'dart:developer' as developer;

class UserControllerState {
  final UserModel? currentUser;
  final bool loading;

  UserControllerState({
    this.currentUser,
    this.loading = false,
  });

  UserControllerState copyWith({
    UserModel? currentUser,
    bool? loading,
  }) {
    return UserControllerState(
      currentUser: currentUser ?? this.currentUser,
      loading: loading ?? this.loading,
    );
  }
}

class UserController extends StateNotifier<UserControllerState> {
  final Ref _ref;

  UserController(this._ref) : super(UserControllerState());

  Future<void> getCurrentUser() async {
    state = state.copyWith(loading: true);

    try {
      final userAPI = _ref.read(userAPIProvider);
      final user = await userAPI.fetchCurrentUser();

      state = state.copyWith(
        currentUser: user,
      );
    } catch (e, stackTrace) {
      developer.log('Error in UserController.getCurrentUser', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);
  }

  Future<void> updateLastViewedVideo(int videoId, BuildContext? context) async {
    try {
      final userAPI = _ref.read(userAPIProvider);
      await userAPI.updateLastViewedVideo(videoId);
    } catch (e, stackTrace) {
      developer.log('Error in UserController.updateLastViewedVideo', error: e.toString(), stackTrace: stackTrace);
      if (context != null && context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    }
  }
}

final userControllerProvider = StateNotifierProvider<UserController, UserControllerState>((ref) {
  return UserController(ref);
});
