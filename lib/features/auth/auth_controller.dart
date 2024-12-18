import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../apis/auth_api.dart';
import '../../core/utils.dart';
import 'dart:async';

// Define the state for authentication
enum AuthState { initial, authenticated, unauthenticated }

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription<bool>? _authStateSubscription;

  AuthController(this._ref) : super(AuthState.initial) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    final authAPI = _ref.read(authAPIProvider);
    _authStateSubscription = authAPI.authStateChange.listen(
      (isAuthenticated) {
        state = isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated;
      },
      onError: (error) {
        developer.log('Error in auth state stream', error: error.toString());
        state = AuthState.unauthenticated;
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> signUp(BuildContext context, {required String email, required String password}) async {
    final previousState = state;
    try {
      _ref.read(authLoadingProvider.notifier).state = true;
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signUp(email: email, password: password);
      state = AuthState.authenticated;
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signUp', error: e.toString(), stackTrace: stackTrace);
      state = previousState;
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signIn(BuildContext context, {required String email, required String password}) async {
    final previousState = state;
    try {
      _ref.read(authLoadingProvider.notifier).state = true;
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signIn(email: email, password: password);
      state = AuthState.authenticated;
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signIn', error: e.toString(), stackTrace: stackTrace);
      state = previousState;
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut(BuildContext context) async {
    final previousState = state;
    try {
      _ref.read(authLoadingProvider.notifier).state = true;
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signOut();
      state = AuthState.unauthenticated;
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      state = previousState;
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }
}
