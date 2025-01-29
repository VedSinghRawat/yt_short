import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/shared_pref.dart';
import '../models/models.dart';

abstract class IUserAPI {
  Future<UserModel?> getUser();
  Future<UserModel?> progressSync(int level, int subLevel);
}

class UserAPI implements IUserAPI {
  final ApiService _apiService;
  UserAPI(this._apiService);

  @override
  Future<UserModel?> getUser() async {
    try {
      final response = await _apiService.call(
        method: Method.get,
        endpoint: '/user/me',
      );

      if (response.statusCode == 401) {
        return await SharedPref.getUser();
      }

      UserModel apiUser = UserModel.fromJson(response.data?['user']);

      await SharedPref.setUser(apiUser);

      return apiUser;
    } catch (e, stackTrace) {
      developer.log('Error getting current user', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<UserModel?> progressSync(int level, int subLevel) async {
    developer.log('level: $level, subLevel: $subLevel', name: 'progressSync');
    try {
      final response = await _apiService.call(
        method: Method.post,
        endpoint: '/user/sync',
        body: {
          'level': level,
          'subLevel': subLevel,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync user progress: ${response.statusCode}');
      }

      return UserModel.fromJson(response.data?['user']);
    } catch (e, stackTrace) {
      developer.log('Error syncing user progress', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  return UserAPI(ref.read(apiServiceProvider));
});
