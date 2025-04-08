import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/utils.dart';
import '../models/models.dart';

abstract class IUserAPI {
  FutureEither<UserDTO> sync(String levelId, int subLevel);
}

class UserAPI implements IUserAPI {
  final ApiService _apiService;
  UserAPI(this._apiService);

  @override
  FutureEither<UserDTO> sync(String levelId, int subLevel) async {
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

      return right(UserDTO.fromJson(response.data?['user']));
    } on DioException catch (e, stackTrace) {
      developer.log('Error syncing user progress', error: e.toString(), stackTrace: stackTrace);

      return left(Failure(message: parseError(e.type)));
    }
  }
}

final userAPIProvider = Provider<IUserAPI>((ref) {
  return UserAPI(ref.read(apiServiceProvider));
});
