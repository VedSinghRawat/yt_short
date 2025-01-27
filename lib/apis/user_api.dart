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
        endpoint: '/me',
      );
      final localUser = await SharedPref.getUser();

      if (response.statusCode == 401) {
        return localUser;
      }

      print(response.data);

      UserModel apiUser = UserModel.fromJson(response.data);

      if (localUser != null &&
          ((localUser.lastProgress != null && apiUser.lastProgress == null) || localUser.lastProgress! > apiUser.lastProgress!) &&
          (localUser.level != null && localUser.subLevel != null)) {
        await progressSync(localUser.level!, localUser.subLevel!);

        apiUser = apiUser.copyWith(level: localUser.level, subLevel: localUser.subLevel);
      }

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
      final googleIdToken = await SharedPref.getGoogleIdToken();
      if (googleIdToken == null) {
        developer.log('Cannot sync: User not signed in');
        return null;
      }

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

      return UserModel.fromJson(response.data);
    } catch (e, stackTrace) {
      developer.log('Error syncing user progress', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  return UserAPI(ref.read(apiServiceProvider));
});
