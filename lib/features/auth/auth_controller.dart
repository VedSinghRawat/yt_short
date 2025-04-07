import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'dart:developer' as developer;
import '../../apis/auth_api.dart';
import '../../core/utils.dart';
import '../user/user_controller.dart';
import 'dart:async';

part 'auth_controller.g.dart';

class AuthControllerState {
  final bool loading;

  AuthControllerState({required this.loading});

  AuthControllerState copyWith({bool? loading}) {
    return AuthControllerState(loading: loading ?? this.loading);
  }
}

@riverpod
class AuthController extends _$AuthController {
  // Internal flag to prevent overlapping requests.
  bool _isProcessing = false;

  @override
  AuthControllerState build() {
    return AuthControllerState(loading: false);
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    try {
      // Access dependencies via ref.
      final authAPI = ref.read(authAPIProvider);
      final userController = ref.read(userControllerProvider.notifier);
      final sublevelController = ref.read(sublevelControllerProvider.notifier);

      final userDTO = await authAPI.signInWithGoogle();
      if (userDTO == null) return;

      final user = userController.updateCurrentUser(userDTO);

      await authAPI.syncCyId();

      await Future.delayed(Duration.zero); // Yield control to UI

      final progress = SharedPref.get(PrefKey.currProgress(
          userEmail: null)); // null because user is not logged in before sign in

      final level = progress?.maxLevel ?? kAuthRequiredLevel;
      final subLevel = progress?.maxSubLevel ?? 1;

      if (context.mounted &&
          (user.maxLevel > level || (user.maxLevel == level && userDTO.maxSubLevel >= subLevel))) {
        await showLevelChangeConfirmationDialog(
          context,
          user.maxLevel,
          userDTO.maxSubLevel,
          sublevelController,
          user.email,
        );
      }

      await sublevelController.handleFetchSublevels();
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signInWithGoogle',
          error: e.toString(), stackTrace: stackTrace);
      final userController = ref.read(userControllerProvider.notifier);
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
      final userController = ref.read(userControllerProvider.notifier);

      final authAPI = ref.read(authAPIProvider);

      final user = ref.read(userControllerProvider).currentUser;

      if (user != null) {
        await userController.sync(user.levelId, user.subLevel);
        await authAPI.signOut();
        userController.removeCurrentUser();
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
