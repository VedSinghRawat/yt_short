import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  factory AuthControllerState.initial() => const AuthControllerState(authState: AuthState.initial, loading: false);

  // CopyWith method for immutable state updates
  AuthControllerState copyWith({AuthState? authState, bool? loading}) {
    return AuthControllerState(authState: authState ?? this.authState, loading: loading ?? this.loading);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthControllerState> {
  final Ref _ref;
  late UserController userController;
  late AuthAPI authAPI;

  StreamSubscription<bool>? _authStateSubscription;

  AuthController(this._ref) : super(AuthControllerState.initial()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    authAPI = _ref.read(authAPIProvider);
    userController = _ref.read(userControllerProvider.notifier);

    _authStateSubscription = authAPI.authStateChange.listen(
      (isAuthenticated) async {
        if (isAuthenticated) userController.getCurrentUser();

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

  Future<void> signUp(BuildContext context, {required String email, required String password}) async {
    state = state.copyWith(loading: true);

    try {
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signUp(email: email, password: password);

      state = state.copyWith(authState: AuthState.authenticated);
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signUp', error: e.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    }

    state = state.copyWith(loading: false);
  }

  Future<void> signIn(BuildContext context, {required String email, required String password}) async {
    state = state.copyWith(loading: true);

    try {
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signIn(email: email, password: password);
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signIn', error: e.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    }

    state = state.copyWith(loading: false);
  }

  Future<void> signOut(BuildContext context) async {
    state = state.copyWith(loading: true);

    try {
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signOut();
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
