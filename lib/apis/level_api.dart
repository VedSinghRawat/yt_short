import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';

abstract class ILevelApi {
  Future<LevelDTO> getById(String id);
  FutureEither<List<String>?> getOrderedIds(String? eTag);
}

class LevelApi implements ILevelApi {
  final ApiService apiService;

  LevelApi({required this.apiService});

  @override
  Future<LevelDTO> getById(String id) async {
    try {
      final response = await apiService.call(
        endpoint: '/levels/output/$id/$id.json', // TODO: change from info service not its dummy
        method: ApiMethod.get,
        customBaseUrl: dotenv.env['S3_BASE_URL'],
      );

      final levelDTO = LevelDTO.fromJson(response.data);

      await SharedPref.setLevelDTO(levelDTO);

      return levelDTO;
    } on DioException catch (e) {
      if (dioConnectionErrors.contains(e.type)) {
        final cachedData = await SharedPref.getLevelDTO(id);
        if (cachedData != null) {
          return cachedData;
        }
      }

      throw Exception(e.response?.data?.toString() ?? e.toString());
    }
  }

  @override
  FutureEither<List<String>?> getOrderedIds(String? eTag) async {
    try {
      final response = await apiService.call(
        endpoint: '/levels/orderedIds.json',
        method: ApiMethod.get,
        headers: eTag != null
            ? {
                'If-None-Match': eTag,
              }
            : null,
        customBaseUrl: dotenv.env['S3_BASE_URL'],
      );

      return right(List<String>.from(response.data['ids']));
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        return right(null);
      }

      return left(
        Failure(
          message: e.response?.data?.toString() ?? e.toString(),
          type: e.type,
        ),
      );
    } catch (e) {
      return left(
        Failure(
          message: e.toString(),
        ),
      );
    }
  }
}

final levelApiProvider = Provider<ILevelApi>((ref) {
  return LevelApi(apiService: ref.read(apiServiceProvider));
});
