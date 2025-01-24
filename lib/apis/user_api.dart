import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/core/shared_pref.dart';
import '../models/models.dart';
import 'package:dio/dio.dart';

abstract class IUserAPI {
  Future<UserModel?> progressSync(int level, int subLevel);
  Future<UserModel?> getCurrentUser();
}

class UserAPI implements IUserAPI {
  final GoogleSignIn _googleSignIn;

  UserAPI(this._googleSignIn);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      return UserModel(
        id: googleUser.id,
        email: googleUser.email,
        level: 1,
        subLevel: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
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

      final dio = Dio();
      final response = await dio.post(
        '${dotenv.env['API_BASE_URL']}/user/sync',
        data: {
          'level': level,
          'subLevel': subLevel,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $googleIdToken',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync user progress: ${response.statusCode}');
      }

      return UserModel.fromJson(response.data);
    } catch (e, stackTrace) {
      // developer.log('Error syncing user progress', error: e.toString(), stackTrace: stackTrace);
      return null;
    }
  }
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  final googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  return UserAPI(googleSignIn);
});
