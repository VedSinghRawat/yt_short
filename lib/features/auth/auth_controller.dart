import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/show_confirmation_dialog.dart';
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

  AuthController(this.userController, this.authAPI, this.contentController)
      : super(AuthControllerState(loading: false));

  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(loading: true);

    try {
      final user = await authAPI.signInWithGoogle();

      if (user == null) return;
      await userController.updateCurrentUser(user);

      final level = (await SharedPref.getCurrProgress())?['level'] ?? kAuthRequiredLevel;

      if ((user.level < level) || !context.mounted) return;

      await showConfirmationDialog(
        context,
        question:
            'We notice that you are already on Level: ${user.level} SubLevel: ${user.subLevel}. Do you continue from there?',
        onResult: (result) async {
          if (!result) return;
          await SharedPref.setCurrProgress(user.level, user.subLevel);
          await contentController.fetchContents();
        },
        yesButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in AuthController.signInWithGoogle',
        error: e.toString(),
        stackTrace: stackTrace,
      );

      userController.removeCurrentUser();

      if (!context.mounted) return;

      showErrorSnackBar(context, e.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    state = state.copyWith(loading: true);

    try {
      await userController.progressSync(
          userController.state.currentUser!.level, userController.state.currentUser!.subLevel);

      await authAPI.signOut();

      await userController.removeCurrentUser();
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    }

    state = state.copyWith(loading: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final userController = ref.watch(userControllerProvider.notifier);
  final authAPI = ref.watch(authAPIProvider);
  final contentController = ref.watch(contentControllerProvider.notifier);

  return AuthController(userController, authAPI, contentController);
});
