import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../apis/auth_api.dart';
import 'dart:async';

// Define the state for authentication
enum AuthState { initial, authenticated, unauthenticated, loading, error }

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

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
        state = AuthState.error;
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      state = AuthState.loading;
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signUp(email: email, password: password);
      state = AuthState.authenticated;
    } catch (e, stackTrace) {
      state = AuthState.error;
      developer.log('Error in AuthController.signUp', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      state = AuthState.loading;
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signIn(email: email, password: password);
      state = AuthState.authenticated;
    } catch (e, stackTrace) {
      state = AuthState.unauthenticated;
      developer.log('Error in AuthController.signIn', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = AuthState.loading;
      final authRepository = _ref.read(authAPIProvider);
      await authRepository.signOut();
      state = AuthState.unauthenticated;
    } catch (e, stackTrace) {
      state = AuthState.error;
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
