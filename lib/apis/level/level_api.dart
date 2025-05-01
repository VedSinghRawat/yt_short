import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/services/path/path_service.dart';
import 'package:myapp/models/level/level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'level_api.g.dart';

abstract class ILevelApi {
  Future<LevelDTO?> get(String id);

  /// Fetches the ordered list of level IDs from cloud storage.
  ///
  /// This method retrieves a JSON file containing an 'orderedIds' key,
  /// whose value is a list of level ID strings in the intended order.
  /// It utilizes ETag caching via [ApiService.getCloudStorageData].
  ///
  /// Returns a [List<String>] containing the ordered level IDs if fetched successfully.
  /// Returns `null` if the data has not changed since the last fetch (HTTP 304 Not Modified),
  /// or if the response data format is unexpected (e.g., missing 'orderedIds' key).
  /// Throws a [APIError] if a network error (other than 304) or data parsing error occurs.
  Future<List<String>?> getOrderedIds();
}

class LevelApi implements ILevelApi {
  final ApiService apiService;

  LevelApi({required this.apiService});

  @override
  Future<LevelDTO?> get(String id) async {
    final response = await apiService.getCloudStorageData(endpoint: PathService.levelJson(id));

    if (response == null) return null;

    final levelDTO = LevelDTO.fromJson({...response.data, 'id': id});

    return levelDTO;
  }

  @override
  Future<List<String>?> getOrderedIds() async {
    final response = await apiService.getCloudStorageData<Map<String, dynamic>>(endpoint: PathService.orderedIds());

    if (response == null) return null;

    final ids = response.data?['orderedIds'];
    if (ids == null) throw APIError(message: 'Ordered IDs not found');

    return List<String>.from(ids);
  }
}

@riverpod
LevelApi levelApi(ref) {
  final apiService = ref.read(apiServiceProvider);

  return LevelApi(apiService: apiService);
}
