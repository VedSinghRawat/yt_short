import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';

abstract class IAuthAPI {
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Stream<bool> get authStateChange;
}

class AuthAPI implements IAuthAPI {
  final SupabaseClient _supabaseClient;

  AuthAPI(SupabaseClient superbaseClient) : _supabaseClient = superbaseClient;

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final response = await _supabaseClient.auth.signUp(email: email, password: password);

      if (response.user == null) {
        throw Exception('Sign up failed: No user data received');
      }
    } on AuthException catch (e) {
      developer.log('Auth Error during sign up', error: '${e.message} (Status: ${e.statusCode})', stackTrace: StackTrace.current);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      developer.log('Unexpected error during sign up', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(email: email, password: password);

      if (response.user == null) {
        throw Exception('Sign in failed: No user data received');
      }
    } on AuthException catch (e) {
      developer.log('Auth Error during sign in', error: '${e.message} (Status: ${e.statusCode})', stackTrace: StackTrace.current);
      throw Exception(e.message);
    } catch (e, stackTrace) {
      developer.log('Unexpected error during sign in', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e, stackTrace) {
      developer.log('Error during sign out', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Stream<bool> get authStateChange => _supabaseClient.auth.onAuthStateChange.map((event) => event.session != null);
}

final authAPIProvider = Provider<AuthAPI>((ref) {
  return AuthAPI(SupabaseConfig.client);
});
