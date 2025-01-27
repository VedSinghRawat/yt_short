import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/models/user/user.dart';

abstract class IAuthAPI {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  Stream<bool> get authStateChange;
}

class AuthAPI implements IAuthAPI {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    clientId: dotenv.env['GOOGLE_SERVER_ID'],
  );

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  final ApiService _apiService;

  AuthAPI({required ApiService apiService}) : _apiService = apiService {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _authStateController.add(account != null);
    });
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign In cancelled or failed');
      }

      final auth = await account.authentication;

      _apiService.setToken(auth.idToken ?? '');

      final response = await _apiService.call(endpoint: '/auth/google', method: Method.get);
      developer.log('Google Sign In response: $response', name: 'api');

      final user = UserModel.fromJson(response.data['user']);

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString());
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
      _authStateController.add(false);
    } catch (e, stackTrace) {
      developer.log('Error during sign out', error: e.toString(), stackTrace: stackTrace);
      throw Exception(e.toString());
    }
  }

  @override
  Stream<bool> get authStateChange => _authStateController.stream;
}

final authAPIProvider = Provider<AuthAPI>((ref) {
  return AuthAPI(apiService: ref.read(apiServiceProvider));
});
