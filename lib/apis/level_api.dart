import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/path_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';

abstract class ILevelApi {
  Future<LevelDTO?> get(String id);
  Future<List<String>?> getOrderedIds();
}

class LevelApi implements ILevelApi {
  final ApiService apiService;
  final PathService pathService;

  LevelApi({required this.apiService, required this.pathService});

  @override
  Future<LevelDTO?> get(String id) async {
    try {
      final response = await apiService.getCloudStorageData(
        endpoint: pathService.levelJsonPath(id),
      );

      if (response == null) return null;

      final levelDTO = LevelDTO.fromJson({...response.data, 'id': id});

      return levelDTO;
    } on DioException catch (e) {
      if (dioConnectionErrors.contains(e.type)) {
        return null;
      }

      throw Failure(message: e.response?.data?.toString() ?? e.toString(), type: e.type);
    }
  }

  @override
  Future<List<String>?> getOrderedIds() async {
    try {
      final response = await apiService.getCloudStorageData<Map<String, dynamic>?>(
        endpoint: pathService.orderedIdsPath(),
      );

      final ids = response?.data?['orderedIds'];
      if (ids == null) return null;

      return List<String>.from(ids);
    } on DioException catch (e) {
      throw Failure(message: e.response?.data.toString() ?? unknownErrorMsg, type: e.type);
    } catch (e) {
      throw Failure(message: e.toString());
    }
  }
}

final levelApiProvider = Provider<ILevelApi>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final pathService = ref.read(pathServiceProvider);

  return LevelApi(apiService: apiService, pathService: pathService);
});
