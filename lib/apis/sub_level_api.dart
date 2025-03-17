import 'dart:developer' as developer show log;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/utils.dart';

class GetZipResponse {
  final Uint8List zipFile;
  final String eTag;

  GetZipResponse({required this.zipFile, required this.eTag});
}

abstract class ISubLevelAPI {
  FutureEither<GetZipResponse?> getZipData(String levelId, int zipId, {String? eTag});
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  FutureEither<GetZipResponse?> getZipData(
    String levelId,
    int zipId, {
    String? eTag,
  }) async {
    try {
      final headers = eTag != null ? {'If-None-Match': eTag} : null;

      final response = await apiService.call(
        endpoint: '/levels/output/$levelId/$zipId.zip', // TODO: change is same as
        customBaseUrl: dotenv.env['S3_BASE_URL'],
        method: ApiMethod.get,
        headers: headers,
        responseType: ResponseType.bytes,
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch");
      }

      final newETag = response.headers.value(HttpHeaders.etagHeader);

      return Right(GetZipResponse(zipFile: response.data, eTag: newETag as String));
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        return const Right(null);
      }

      developer.log('Error in SubLevelAPI.getZipData: $e');
      return Left(Failure(message: e.toString()));
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI(ref.read(apiServiceProvider));
});
