import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/models/level/level.dart';

abstract class ILevelApi {
  Future<LevelDTO> getById(String id);
}

class LevelApi implements ILevelApi {
  final ApiService apiService;

  LevelApi({required this.apiService});

  @override
  Future<LevelDTO> getById(String id) async {
    try {
      final response = await apiService.call(
        endpoint: '/levels/$id.json',
        method: ApiMethod.get,
        customBaseUrl: dotenv.env['S3_BASE_URL'],
      );

      return LevelDTO.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? e.toString());
    }
  }
}

final levelApiProvider = Provider<LevelApi>((ref) {
  return LevelApi(apiService: ref.read(apiServiceProvider));
});
