import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../apis/user_api.dart';
import '../../models/models.dart';
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
  final IUserAPI userAPI;

  UserController(this.userAPI) : super(UserControllerState());

  Future<void> getCurrentUser() async {
    state = state.copyWith(loading: true);

    try {
      final user = await userAPI.getUser();
      state = state.copyWith(
        currentUser: user,
      );
    } catch (e, stackTrace) {
      developer.log('Error in UserController.getCurrentUser', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);
  }

  Future<void> progressSync(int level, int subLevel) async {
    try {
      final user = await userAPI.progressSync(level, subLevel);
      if (user == null) return;

      state = state.copyWith(currentUser: user);
    } catch (e, stackTrace) {
      developer.log('Error in UserController.updateLastViewedVideo', error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final userControllerProvider = StateNotifierProvider<UserController, UserControllerState>((ref) {
  final userAPI = ref.read(userAPIProvider);
  return UserController(userAPI);
});
