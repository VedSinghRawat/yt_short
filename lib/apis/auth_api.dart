import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/google_sign_in.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/user/user.dart';

abstract class IAuthAPI {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
}

class AuthAPI implements IAuthAPI {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn;

  AuthAPI({required ApiService apiService, required GoogleSignIn googleSignIn})
      : _apiService = apiService,
        _googleSignIn = googleSignIn;

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw Exception('Google Sign In cancelled or failed');
      }

      final auth = await account.authentication;

      await _apiService.setToken(auth.idToken ?? '');

      final response = await _apiService.call(endpoint: '/auth/google', method: Method.get);

      final user = UserModel.fromJson(response.data['user']);

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.toString());
    } catch (e, stackTrace) {
      developer.log('Error during Google Sign In', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _apiService.setToken('');

      await SharedPref.clearAll();
    } catch (e, stackTrace) {
      developer.log('Error during sign out', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }
}

final authAPIProvider = Provider<AuthAPI>((ref) {
  return AuthAPI(
      apiService: ref.read(apiServiceProvider), googleSignIn: ref.read(googleSignInProvider));
});
