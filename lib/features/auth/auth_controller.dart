import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/content/content_controller.dart';
import 'dart:developer' as developer;
import '../../apis/auth_api.dart';
import '../../core/utils.dart';
import '../user/user_controller.dart';
import 'dart:async';

class AuthControllerState {
  final bool loading;

  AuthControllerState({required this.loading});

  AuthControllerState copyWith({bool? loading}) {
    return AuthControllerState(loading: loading ?? this.loading);
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  final UserController userController;
  final AuthAPI authAPI;
  final ContentController contentController;
  bool _isProcessing = false;

  AuthController(this.userController, this.authAPI, this.contentController)
      : super(AuthControllerState(loading: false));

  Future<void> signInWithGoogle(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    try {
      final user = await authAPI.signInWithGoogle();
      if (user == null) return;

      await userController.updateCurrentUser(user);
      await Future.delayed(Duration.zero); // Yield control to UI

      final progress = await SharedPref.getCurrProgress();
      final level = progress?['level'] ?? kAuthRequiredLevel;
      final subLevel = progress?['subLevel'] ?? 0;

      if (context.mounted &&
          (user.level > level || (user.level == level && user.subLevel >= subLevel))) {
        await showLevelChangeConfirmationDialog(context, user, contentController);
      }

      await contentController.fetchContents();
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signInWithGoogle',
          error: e.toString(), stackTrace: stackTrace);

      userController.removeCurrentUser();
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      _isProcessing = false;
      state = state.copyWith(loading: false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    try {
      final user = userController.state.currentUser;
      if (user != null) {
        await userController.progressSync(user.level, user.subLevel);
        await authAPI.signOut();
        await userController.removeCurrentUser();
        await Future.delayed(Duration.zero); // Allow UI to update
      }
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      _isProcessing = false;
      state = state.copyWith(loading: false);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final userController = ref.watch(userControllerProvider.notifier);
  final authAPI = ref.watch(authAPIProvider);
  final contentController = ref.watch(contentControllerProvider.notifier);
  return AuthController(userController, authAPI, contentController);
});
