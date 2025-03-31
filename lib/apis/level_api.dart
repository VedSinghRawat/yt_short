import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';

abstract class ILevelApi {
  FutureEither<LevelDTO> getById(
    String id,
  );
  FutureEither<List<String>?> getOrderedIds();
}

class LevelApi implements ILevelApi {
  final ApiService apiService;

  LevelApi({required this.apiService});

  @override
  FutureEither<LevelDTO> getById(String id) async {
    LevelDTO? cachedLevelDTO = await SharedPref.getRawValue(
      PrefKey.levelDTOKey(
        id,
      ),
    );

    try {
      final response = await apiService.getCloudStorageData(
        params: ApiParams(
          endpoint: getLevelJsonPath(id),
          method: ApiMethod.get,
          baseUrl: BaseUrl.s3,
        ),
      );

      if (response == null && cachedLevelDTO != null) return right(cachedLevelDTO);
      if (response == null) throw '';

      final levelDTO = LevelDTO.fromJson(response.data);

      await SharedPref.storeRawValue(
        PrefKey.levelDTOKey(
          levelDTO.id,
        ),
        levelDTO,
      );

      return right(levelDTO);
    } on DioException catch (e) {
      if (dioConnectionErrors.contains(e.type)) {
        if (cachedLevelDTO != null) return right(cachedLevelDTO);
      }

      return left(
        Failure(
          message: e.response?.data?.toString() ?? e.toString(),
          type: e.type,
        ),
      );
    }
  }

  @override
  FutureEither<List<String>?> getOrderedIds() async {
    try {
      final response = await apiService.getCloudStorageData<Map<String, dynamic>?>(
        params: ApiParams(
          endpoint: '/levels/orderedIds.json',
          method: ApiMethod.get,
          baseUrl: BaseUrl.s3,
        ),
      );

      final ids = response?.data?['ids'];
      if (ids == null) return right(null);

      return right(List<String>.from(ids));
    } on DioException catch (e) {
      return left(
        Failure(
          message: e.response?.data.toString() ?? unknownErrorMsg,
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
