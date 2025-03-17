import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/utils.dart';

abstract class IInitializeAPI {
  FutureEither<Map<String, dynamic>> initialize(String currentVersion);
}

class InitializeAPI implements IInitializeAPI {
  final ApiService _apiService;

  InitializeAPI(this._apiService);

  @override
  FutureEither<Map<String, dynamic>> initialize(String currentVersion) async {
    try {
      final response = await _apiService.call(
        endpoint: '/initialize',
        method: ApiMethod.post,
        body: {
          'version': currentVersion,
        },
      );

      return Right(response.data!);
    } on DioException catch (e) {
      return Left(Failure(message: e.response?.data?['message'] ?? 'Failed to initialize'));
    }
  }
}

final initializeAPIService = Provider<InitializeAPI>((ref) {
  return InitializeAPI(ref.read(apiServiceProvider));
});
