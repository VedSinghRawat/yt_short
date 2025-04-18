import 'dart:developer' as developer show log;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/path_service.dart';

abstract class ISubLevelAPI {
  Future<Uint8List?> getVideo(String levelId, String videoFilename);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService, this.pathService);

  final ApiService apiService;
  final PathService pathService;

  @override
  Future<Uint8List?> getVideo(String levelId, String videoFilename) async {
    try {
      final response = await apiService.getCloudStorageData(
        endpoint: pathService.videoPath(levelId, videoFilename),
        responseType: ResponseType.bytes,
      );

      return response?.data;
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getVideo: $e');
      throw Failure(message: e.toString());
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final pathService = ref.read(pathServiceProvider);

  return SubLevelAPI(apiService, pathService);
});
