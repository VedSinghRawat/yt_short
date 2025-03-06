import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';

abstract class IVersionAPI {
  Future<Map<String, dynamic>> getVersion(String currentVersion);
}

class VersionAPI implements IVersionAPI {
  final ApiService _apiService;

  VersionAPI(this._apiService);

  @override
  Future<Map<String, dynamic>> getVersion(String currentVersion) async {
    try {
      final response = await _apiService.call(
        endpoint: '/check_version?version=$currentVersion',
        method: Method.get,
      );

      return response.data!;
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? 'Failed to get version';
    }
  }
}

final versionAPIService = Provider<VersionAPI>((ref) {
  return VersionAPI(ref.read(apiServiceProvider));
});
