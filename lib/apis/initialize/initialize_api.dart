import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initialize_api.freezed.dart';
part 'initialize_api.g.dart';

@freezed
class InitializeResponse with _$InitializeResponse {
  const factory InitializeResponse({UserDTO? user}) = _InitializeResponse;

  factory InitializeResponse.fromJson(Map<String, dynamic> json) => _$InitializeResponseFromJson(json);
}

abstract class IInitializeAPI {
  Future<InitializeResponse> initialize(String currentVersion);
}

class InitializeAPI implements IInitializeAPI {
  final ApiService _apiService;

  InitializeAPI(this._apiService);

  @override
  Future<InitializeResponse> initialize(String currentVersion) async {
    final response = await _apiService.call(
      params: ApiParams(endpoint: '/initialize?version=$currentVersion', method: ApiMethod.get),
    );

    return InitializeResponse.fromJson(response.data!);
  }
}

@riverpod
InitializeAPI initializeAPI(ref) {
  return InitializeAPI(ref.read(apiServiceProvider));
}
