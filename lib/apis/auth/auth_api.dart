import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/googleSignIn/google_sign_in.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

abstract class IAuthAPI {
  Future<UserDTO?> signInWithGoogle();
  Future<void> signOut();
  Future<void> syncCyId();
}

class AuthAPI implements IAuthAPI {
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn;

  AuthAPI(this._apiService, this._googleSignIn);

  @override
  Future<UserDTO?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();

    if (account == null) {
      throw Exception('Google Sign In cancelled or failed');
    }

    final auth = await account.authentication;

    if (auth.idToken == null) {
      throw APIError(message: 'Google Sign In failed. No id token.');
    }

    await _apiService.setToken(auth.idToken ?? '');

    final response = await _apiService.call(params: const ApiParams(endpoint: '/auth/google', method: ApiMethod.get));

    final user = UserDTO.fromJson(response.data['user']);

    return user;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _apiService.setToken('');
  }

  @override
  Future<void> syncCyId() async {
    final cyId = SharedPref.get(PrefKey.cyId);

    if (cyId == null || cyId.isEmpty) return;

    await _apiService.call(
      params: ApiParams(endpoint: '/user/sync-cy-id', method: ApiMethod.post, body: {'cyId': cyId}),
    );

    await SharedPref.store(PrefKey.cyId, ''); // set cyId to empty string to indicate that it has been synced
  }
}

@riverpod
AuthAPI authAPI(ref) {
  return AuthAPI(ref.read(apiServiceProvider), ref.read(googleSignInProvider));
}
