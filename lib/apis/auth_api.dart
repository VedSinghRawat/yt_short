import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_config.dart';
import '../models/models.dart';

abstract class IAuthAPI {
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<bool> get authStateChange;
}

class AuthAPI implements IAuthAPI {
  final SupabaseClient _supabaseClient = SupabaseConfig.client;

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

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
  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabaseClient.from('users').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e, stackTrace) {
      developer.log('Error getting current user', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Stream<bool> get authStateChange => _supabaseClient.auth.onAuthStateChange.map((event) => event.session != null);
}

final authAPIProvider = Provider<IAuthAPI>((ref) {
  return AuthAPI();
});

// Provider for the current user
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authAPI = ref.watch(authAPIProvider);
  return authAPI.getCurrentUser();
});
