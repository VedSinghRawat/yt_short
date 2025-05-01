import 'dart:developer' as developer show log;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';

abstract class ISubLevelAPI {
  Future<Uint8List?> getDialogueZip(int zipNum);
  Future<Uint8List?> getVideo(String levelId, String videoFilename);
  Future<Uint8List?> getAudio(String levelId, String audioFilename);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI(this.apiService);

  final ApiService apiService;

  @override
  Future<Uint8List?> getVideo(String levelId, String videoFilename) async {
    try {
      final response = await apiService.getCloudStorageData(
        endpoint: PathService.video(levelId, videoFilename),
        responseType: ResponseType.bytes,
      );

      return response?.data;
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getVideo: $e');
      throw Failure(message: e.toString());
    }
  }

  @override
  Future<Uint8List?> getDialogueZip(int zipNum) async {
    try {
      final response = await apiService.getCloudStorageData<Uint8List?>(
        endpoint: '/dialogues/zips/$zipNum.zip',
        responseType: ResponseType.bytes,
      );

      return response?.data;
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getDialogueZip for zipNum $zipNum: $e');
      throw Failure(message: e.toString());
    }
  }

  @override
  Future<Uint8List?> getAudio(String levelId, String audioFilename) async {
    try {
      final response = await apiService.getCloudStorageData(
        endpoint: PathService.audio(levelId, audioFilename),
        responseType: ResponseType.bytes,
      );

      return response?.data;
    } on DioException catch (e) {
      developer.log('Error in SubLevelAPI.getAudio: $e');
      throw Failure(message: e.toString());
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  final apiService = ref.read(apiServiceProvider);

  return SubLevelAPI(apiService);
});
