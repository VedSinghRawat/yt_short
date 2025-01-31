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

// Define the state for authentication
enum AuthState { initial, authenticated, unauthenticated }

class AuthControllerState {
  final AuthState authState;
  final bool loading;

  const AuthControllerState({required this.authState, required this.loading});

  // Initial state factory constructor
  factory AuthControllerState.initial() =>
      const AuthControllerState(authState: AuthState.initial, loading: false);

  // CopyWith method for immutable state updates
  AuthControllerState copyWith({AuthState? authState, bool? loading}) {
    return AuthControllerState(
        authState: authState ?? this.authState, loading: loading ?? this.loading);
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  final UserController userController;
  final AuthAPI authAPI;
  final ContentController contentController;

  StreamSubscription<bool>? _authStateSubscription;

  AuthController(this.userController, this.authAPI, this.contentController)
      : super(AuthControllerState.initial()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _authStateSubscription = authAPI.authStateChange.listen(
      (isAuthenticated) async {
        if (isAuthenticated) await userController.getCurrentUser();

        state = state.copyWith(
          authState: isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated,
        );
      },
      onError: (error) {
        developer.log('Error in auth state stream', error: error.toString());
        state = state.copyWith(
          authState: AuthState.unauthenticated,
        );
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(loading: true);

    try {
      final user = await authAPI.signInWithGoogle();

      if (user == null) return;
      await userController.updateCurrentUser(user);

      state = state.copyWith(authState: AuthState.authenticated);

      if (user.level < kAuthRequiredLevel || !context.mounted) return;

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
      if (!context.mounted) return;
      showErrorSnackBar(context, e.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    state = state.copyWith(loading: true);

    try {
      await authAPI.signOut();

      await userController.removeCurrentUser();

      state = state.copyWith(
        authState: AuthState.unauthenticated,
      );
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
  final userController = ref.read(userControllerProvider.notifier);
  final authAPI = ref.read(authAPIProvider);
  final contentController = ref.read(contentControllerProvider.notifier);

  return AuthController(userController, authAPI, contentController);
});
