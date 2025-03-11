import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/models/Level/level_dto.dart';

abstract class ILevelApi {
  Future<LevelDto> getById(String id);
}

class LevelApi implements ILevelApi {
  final ApiService apiService;

  LevelApi({required this.apiService});

  @override
  Future<LevelDto> getById(String id) async {
    try {
      final response = await apiService.call(
        endpoint: '/levels/$id.json',
        method: ApiMethod.get,
        customBaseUrl: dotenv.env['S3_BASE_URL'],
      );

      return LevelDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.toString());
    }
  }
}
