import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/level/level.dart';

abstract class ILevelApi {
  FutureEither<LevelDTO?> get(String id);
  FutureEither<List<String>?> getOrderedIds();
}

class LevelApi implements ILevelApi {
  final ApiService apiService;

  LevelApi({required this.apiService});

  @override
  FutureEither<LevelDTO?> get(String id) async {
    try {
      final response = await apiService.getCloudStorageData(
        endpoint: getLevelJsonPath(id),
      );

      if (response == null) return right(null);

      final levelDTO = LevelDTO.fromJson({...response.data, 'id': id});

      return right(levelDTO);
    } on DioException catch (e) {
      if (dioConnectionErrors.contains(e.type)) {
        return right(null);
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
      final response = await apiService
          .getCloudStorageData<Map<String, dynamic>?>(
            endpoint: getOrderedIdsPath(),
          );

      final ids = response?.data?['orderedIds'];
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
      return left(Failure(message: e.toString()));
    }
  }
}

final levelApiProvider = Provider<ILevelApi>((ref) {
  final apiService = ref.read(apiServiceProvider);

  return LevelApi(apiService: apiService);
});
