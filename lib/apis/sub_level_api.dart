import 'dart:developer' as developer show log;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/level_service.dart';
import 'package:myapp/core/utils.dart';

abstract class ISubLevelAPI {
  FutureEither<Uint8List?> getVideo(String levelId, String videoFilename);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService, this.levelService);

  final ApiService apiService;
  final LevelService levelService;

  @override
  FutureEither<Uint8List?> getVideo(String levelId, String videoFilename) async {
    try {
      final response = await apiService.getCloudStorageData(
        endpoint: levelService.getVideoPath(levelId, videoFilename),
        responseType: ResponseType.bytes,
      );

      return Right(response?.data);
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getVideo: $e');
      return Left(Failure(message: e.toString()));
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final levelService = ref.read(levelServiceProvider);

  return SubLevelAPI(apiService, levelService);
});
