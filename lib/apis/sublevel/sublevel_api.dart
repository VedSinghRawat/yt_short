import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_api.g.dart';

abstract class ISubLevelAPI {
  Future<Uint8List?> getAsset(String levelId, String id, AssetType type);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  Future<Uint8List?> getAsset(String levelId, String id, AssetType type) async {
    final response = await apiService.getCloudStorageData(
      endpoint: PathService.sublevelAsset(levelId, id, type),
      responseType: ResponseType.bytes,
    );

    return response?.data;
  }
}

@riverpod
SubLevelAPI subLevelAPI(ref) {
  final apiService = ref.read(apiServiceProvider);
  return SubLevelAPI(apiService);
}
