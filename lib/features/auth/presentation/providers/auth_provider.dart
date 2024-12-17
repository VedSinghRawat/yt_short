import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../data/repositories/auth_repository_impl.dart';

final authStateProvider = StreamProvider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChange;
});

final authControllerProvider = Provider((ref) => AuthController(ref));

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signUp(
        email: email,
        password: password,
      );
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signUp', error: e.toString(), stackTrace: stackTrace);
      rethrow; // Rethrow to let UI handle the error
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signIn(
        email: email,
        password: password,
      );
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signIn', error: e.toString(), stackTrace: stackTrace);
      rethrow; // Rethrow to let UI handle the error
    }
  }

  Future<void> signOut() async {
    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.signOut();
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      rethrow; // Rethrow to let UI handle the error
    }
  }
}
