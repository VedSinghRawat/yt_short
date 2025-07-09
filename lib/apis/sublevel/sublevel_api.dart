import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sublevel_api.g.dart';

abstract class ISubLevelAPI {
  Future<Uint8List?> getVideo(String levelId, String id);
  Future<Uint8List?> getAudio(String levelId, String id);
  Future<Uint8List?> getImage(String levelId, String id);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  Future<Uint8List?> getVideo(String levelId, String id) async {
    final response = await apiService.getCloudStorageData(
      endpoint: PathService.sublevelAsset(levelId, id, AssetType.video),
      responseType: ResponseType.bytes,
    );

    return response?.data;
  }

  @override
  Future<Uint8List?> getAudio(String levelId, String id) async {
    final response = await apiService.getCloudStorageData(
      endpoint: PathService.sublevelAsset(levelId, id, AssetType.audio),
      responseType: ResponseType.bytes,
    );

    return response?.data;
  }

  @override
  Future<Uint8List?> getImage(String levelId, String id) async {
    final response = await apiService.getCloudStorageData(
      endpoint: PathService.sublevelAsset(levelId, id, AssetType.image),
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
