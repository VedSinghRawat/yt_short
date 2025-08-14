import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_api.g.dart';

abstract class IUserAPI {
  Future<UserDTO> sync(String levelId, int subLevel);
  Future<UserDTO?> resetProfile(String email);
  Future<UserDTO> updateProfile({required PrefLang prefLang});
}

class UserAPI implements IUserAPI {
  final ApiService _apiService;
  UserAPI(this._apiService);

  @override
  Future<UserDTO> sync(String levelId, int subLevel) async {
    try {
      final response = await _apiService.call(
        params: ApiParams(
          method: ApiMethod.post,
          endpoint: '/user/sync',
          body: {'levelId': levelId, 'subLevel': subLevel},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync user progress: ${response.statusCode}');
      }

      return UserDTO.fromJson(response.data?['user']);
    } on DioException catch (e, stackTrace) {
      developer.log('Error syncing user progress', error: e.toString(), stackTrace: stackTrace);

      rethrow;
    }
  }

  @override
  Future<UserDTO> updateProfile({required PrefLang prefLang}) async {
    try {
      final response = await _apiService.call(
        params: ApiParams(method: ApiMethod.patch, endpoint: '/user/profile', body: {'prefLang': prefLang.name}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }

      return UserDTO.fromJson(response.data?['user']);
    } catch (e, stackTrace) {
      developer.log('Error updating user profile', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<UserDTO> resetProfile(String email) async {
    final response = await _apiService.call(
      params: ApiParams(endpoint: '/user/reset', method: ApiMethod.post, body: {'email': email}),
    );

    if (response.data?['user'] == null) {
      throw Exception('Failed to reset profile');
    }

    return UserDTO.fromJson(response.data['user']);
  }
}

@riverpod
UserAPI userAPI(ref) {
  return UserAPI(ref.read(apiServiceProvider));
}
