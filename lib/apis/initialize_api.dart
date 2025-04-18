import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/services/info_service.dart';
import 'package:myapp/models/user/user.dart';

part 'initialize_api.freezed.dart';
part 'initialize_api.g.dart';

@freezed
class InitializeResponse with _$InitializeResponse implements VersionData {
  const factory InitializeResponse({required bool closable, String? content, UserDTO? user}) =
      _InitializeResponse;

  factory InitializeResponse.fromJson(Map<String, dynamic> json) =>
      _$InitializeResponseFromJson(json);
}

abstract class IInitializeAPI {
  Future<InitializeResponse> initialize(String currentVersion);
}

class InitializeAPI implements IInitializeAPI {
  final ApiService _apiService;

  InitializeAPI(this._apiService);

  @override
  Future<InitializeResponse> initialize(String currentVersion) async {
    try {
      final response = await _apiService.call(
        params: ApiParams(endpoint: '/initialize?version=$currentVersion', method: ApiMethod.get),
      );

      return InitializeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Failure(message: e.response?.data ?? 'Failed to initialize');
    }
  }
}

final initializeAPIService = Provider<InitializeAPI>((ref) {
  return InitializeAPI(ref.read(apiServiceProvider));
});
