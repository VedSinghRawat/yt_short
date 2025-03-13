import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';

class GetZipResponse {
  final String zipFile;
  final String eTag;

  GetZipResponse({required this.zipFile, required this.eTag});
}

abstract class ISubLevelAPI {
  Future<GetZipResponse?> getZipData(String levelId, int zipId, {String? eTag});
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  Future<GetZipResponse?> getZipData(
    String levelId,
    int zipId, {
    String? eTag,
  }) async {
    final headers = eTag != null ? {'If-None-Match': eTag} : null;

    final response = await apiService.call(
      endpoint: '/levels/$levelId/zips/$zipId.zip',
      customBaseUrl: dotenv.env['S3_BASE_URL'],
      method: ApiMethod.get,
      headers: headers,
    );

    if (response.statusCode == 304) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch");
    }

    return GetZipResponse(zipFile: response.data, eTag: response.headers['etag'] as String);
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI(ref.read(apiServiceProvider));
});
