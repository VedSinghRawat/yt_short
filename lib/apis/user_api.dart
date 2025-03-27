import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import '../models/models.dart';

abstract class IUserAPI {
  Future<UserModel?> getUser();
  Future<UserModel?> progressSync(String levelId, int subLevel);
}

class UserAPI implements IUserAPI {
  final ApiService _apiService;
  UserAPI(this._apiService);

  @override
  Future<UserModel?> getUser() async {
    try {
      final response = await _apiService.call(
        params: const ApiParams(
          method: ApiMethod.get,
          endpoint: '/user/me',
        ),
      );

      UserModel apiUser = UserModel.fromJson(response.data?['user']);

      return apiUser;
    } catch (e, stackTrace) {
      developer.log('Error getting current user', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<UserModel?> progressSync(String levelId, int subLevel) async {
    try {
      final response = await _apiService.call(
          params: ApiParams(
        method: ApiMethod.post,
        endpoint: '/user/sync',
        body: {
          'levelId': levelId,
          'subLevel': subLevel,
        },
      ));

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
