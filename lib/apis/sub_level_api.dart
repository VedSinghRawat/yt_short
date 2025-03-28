import 'dart:developer' as developer show log;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/utils.dart';

abstract class ISubLevelAPI {
  FutureEither<Uint8List?> getZipData(String levelId, int zipId);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  FutureEither<Uint8List?> getZipData(
    String levelId,
    int zipNum,
  ) async {
    try {
      final response = await apiService.getCloudStorageData<Uint8List?>(
        params: ApiParams(
          endpoint: getLevelZipPath(levelId, zipNum),
          baseUrl: BaseUrl.s3,
          method: ApiMethod.get,
          responseType: ResponseType.bytes,
        ),
      );

      if (response?.statusCode != 200) {
        throw Exception("Failed to fetch");
      }

      return Right(response?.data);
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getZipData: $e');
      return Left(Failure(message: e.toString()));
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI(ref.read(apiServiceProvider));
});
