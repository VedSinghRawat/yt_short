import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/auth/auth_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

class AuthService {
  final IAuthAPI authAPI;
  final PrefLang lang;

  AuthService(this.authAPI, this.lang);

  FutureEither<UserDTO> signInWithGoogle() async {
    try {
      final userDTO = await authAPI.signInWithGoogle();

      if (userDTO == null) {
        return left(APIError(message: 'Sign in failed', trace: StackTrace.current));
      }

      return right(userDTO);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }

  FutureEither<void> signOut() async {
    try {
      await authAPI.signOut();
      return right(null);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }

  FutureEither<void> syncCyId() async {
    try {
      await authAPI.syncCyId();
      return right(null);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }

  FutureEither<UserDTO> resetProfile() async {
    try {
      final userDTO = await authAPI.resetProfile();

      if (userDTO == null) {
        return left(APIError(message: 'Reset profile failed', trace: StackTrace.current));
      }

      return right(userDTO);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }
}

@riverpod
AuthService authService(Ref ref) {
  final authAPI = ref.watch(authAPIProvider);
  final lang = ref.watch(langControllerProvider);
  return AuthService(authAPI, lang);
}
