import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/user/user_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_service.g.dart';

class UserService {
  final IUserAPI userAPI;
  final PrefLang lang;

  UserService(this.userAPI, this.lang);

  FutureEither<UserDTO> sync(String levelId, int subLevel) async {
    try {
      final userDTO = await userAPI.sync(levelId, subLevel);
      return right(userDTO);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }

  FutureEither<UserDTO> updateProfile({required PrefLang prefLang}) async {
    try {
      final userDTO = await userAPI.updateProfile(prefLang: prefLang);
      return right(userDTO);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }

  FutureEither<UserDTO> resetProfile(String email) async {
    try {
      final userDTO = await userAPI.resetProfile(email);
      if (userDTO == null) {
        return left(APIError(message: 'Failed to reset profile', trace: StackTrace.current));
      }
      return right(userDTO);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }
}

@riverpod
UserService userService(Ref ref) {
  final userAPI = ref.read(userAPIProvider);
  final lang = ref.read(langControllerProvider);
  return UserService(userAPI, lang);
}
