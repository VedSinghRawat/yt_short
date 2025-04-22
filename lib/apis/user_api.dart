import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import '../models/models.dart';

abstract class IUserAPI {
  Future<UserDTO> sync(String levelId, int subLevel);
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
        params: ApiParams(
          method: ApiMethod.patch,
          endpoint: '/user/profile',
          body: {'prefLang': prefLang.name},
        ),
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
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  return UserAPI(ref.read(apiServiceProvider));
});
