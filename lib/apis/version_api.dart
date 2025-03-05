import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'dart:developer' as developer;

abstract class IVersionAPI {
  Future<VersionType?> getVersion(String currentVersion);
}

enum VersionType {
  required,
  suggested,
}

class VersionAPI implements IVersionAPI {
  final ApiService _apiService;

  VersionAPI(this._apiService);

  @override
  Future<VersionType?> getVersion(String currentVersion) async {
    try {
      final response = await _apiService.call(
        endpoint: '/check_version?version=$currentVersion',
        method: Method.get,
      );

      final versionTypeString = response.data?['status'] as String?;

      if (versionTypeString == null) {
        return null;
      }

      final versionType = VersionType.values.byName(versionTypeString);

      return versionType;
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? 'Failed to get version';
    }
  }
}

final versionAPIService = Provider<VersionAPI>((ref) {
  return VersionAPI(ref.read(apiServiceProvider));
});
