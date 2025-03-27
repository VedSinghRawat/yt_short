import 'dart:developer' as developer show log;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/utils.dart';

abstract class ISubLevelAPI {
  FutureEither<Uint8List?> getZipData(String levelId, int zipId, String eTagKey);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  FutureEither<Uint8List?> getZipData(
    String levelId,
    int zipId,
    String eTagKey,
  ) async {
    try {
      final response = await apiService.callWithETag<Uint8List?>(
        params: ApiParams(
          endpoint: '/levels/$levelId/zips/$zipId.zip',
          customBaseUrl: dotenv.env['S3_BASE_URL'],
          method: ApiMethod.get,
          responseType: ResponseType.bytes,
        ),
        eTagId: eTagKey,
        onCacheHit: (e) async => null,
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch");
      }

      return Right(response.data);
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getZipData: $e');
      return Left(Failure(message: e.toString()));
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI(ref.read(apiServiceProvider));
});
