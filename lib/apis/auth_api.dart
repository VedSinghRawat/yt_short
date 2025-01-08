import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class IAuthAPI {
  Future<GoogleSignInAccount?> signInWithGoogle();
  Future<void> signOut();
  Stream<bool> get authStateChange;
}

class AuthAPI implements IAuthAPI {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  AuthAPI() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _authStateController.add(account != null);
    });
  }

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      developer.log(_googleSignIn.clientId ?? 'Client ID is null');
      final account = await _googleSignIn.signIn();
      developer.log(account.toString());
      if (account == null) {
        throw Exception('Google Sign In cancelled or failed');
      }
      return account;
    } catch (e, stackTrace) {
      developer.log('Error during Google Sign In', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e, stackTrace) {
      developer.log('Error during sign out', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Stream<bool> get authStateChange => _authStateController.stream;
}

final authAPIProvider = Provider<AuthAPI>((ref) {
  return AuthAPI();
});
