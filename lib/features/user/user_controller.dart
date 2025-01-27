import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import '../../apis/user_api.dart';
import '../../models/models.dart';
import 'dart:developer' as developer;

class UserControllerState {
  final Map<String, UserModel> user;
  final bool loading;
  final String? currentUserEmail;

  UserControllerState({
    this.user = const {},
    this.loading = false,
    this.currentUserEmail,
  });

  UserControllerState copyWith({
    Map<String, UserModel>? user,
    bool? loading,
    String? currentUserEmail,
  }) {
    return UserControllerState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      currentUserEmail: currentUserEmail ?? this.currentUserEmail,
    );
  }
}

class UserController extends StateNotifier<UserControllerState> {
  final IUserAPI userAPI;

  UserController(this.userAPI) : super(UserControllerState());

  Future<UserModel?> getCurrentUser() async {
    state = state.copyWith(loading: true);

    try {
      final user = await userAPI.getUser();

      if (user == null) return null;

      await updateUser(user);

      state = state.copyWith(currentUserEmail: user.email);

      return user;
    } catch (e, stackTrace) {
      developer.log('Error in UserController.getCurrentUser', error: e.toString(), stackTrace: stackTrace);
    }

    state = state.copyWith(loading: false);

    return null;
  }

  Future<void> updateUser(UserModel user) async {
    state = state.copyWith(user: {...state.user, user.email: user});
  }

  updateCurrentUserEmail(String email) {
    state = state.copyWith(currentUserEmail: email);
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
