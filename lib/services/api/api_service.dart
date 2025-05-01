import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/obstructiveError/obstructive_error_controller.dart';
import 'package:myapp/services/googleSignIn/google_sign_in.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_service.freezed.dart';

enum ApiMethod { get, post, put, delete, patch }

@freezed
class ApiParams with _$ApiParams {
  const factory ApiParams({
    required String endpoint,
    required ApiMethod method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    BaseUrl? baseUrl,
    ResponseType? responseType,
  }) = _ApiParams;
}

class BaseUrl {
  final String name;
  final String url;

  BaseUrl._({required this.name, required this.url});

  static final BaseUrl backend = BaseUrl._(name: 'backend', url: dotenv.env['API_BASE_URL'] ?? '');
  static final BaseUrl s3 = BaseUrl._(name: 's3', url: dotenv.env['S3_BASE_URL'] ?? '');

  static final BaseUrl cloudflare = BaseUrl._(name: 'cloudflare', url: dotenv.env['CLOUDFLARE_BASE_URL'] ?? '');

  bool get isS3 => name == 's3';

  @override
  String toString() => '$name: $url';
}

class ApiService {
  final Dio _dio = Dio();
  final GoogleSignIn _googleSignIn;
  final ObstructiveErrorController _obstructiveErrorController;

  ApiService({required GoogleSignIn googleSignIn, required ObstructiveErrorController obstructiveErrorController})
    : _googleSignIn = googleSignIn,
      _obstructiveErrorController = obstructiveErrorController;

  Future<void> setToken(String token) async {
    await SharedPref.store(PrefKey.googleIdToken, token);
  }

  String? getToken() {
    return SharedPref.get(PrefKey.googleIdToken);
  }

  Future<Response<T>> call<T>({required ApiParams params}) async {
    final String? token = getToken();

    final effectiveHeaders = {
      'Content-Type': 'application/json',
      if (token != null && params.baseUrl?.isS3 != true) 'Authorization': 'Bearer $token',
      ...?params.headers,
    };

    final baseUrl =
        params.baseUrl != null
            ? '${params.baseUrl?.url}${params.endpoint}'
            : '${BaseUrl.backend.url}${params.endpoint}';
    try {
      final options = Options(
        method: params.method.name.toUpperCase(),
        headers: effectiveHeaders,
        responseType: params.responseType,
        contentType: 'application/json',
      );
      return await _dio.request(baseUrl, data: params.body, options: options);
    } on DioException catch (e) {
      if (e.response?.statusCode == AppConstants.obstructiveErrorStatus) {
        _obstructiveErrorController.showObstructiveError(e.response?.data['content']);

        return e.response as Response<T>;
      }

      if ((e.response?.statusCode ?? 0) != 304) {
        developer.log('ApiError on uri $baseUrl: ${e.response?.data}');
      }

      if (e.response?.data == null ||
          e.response?.data is! Map<String, dynamic> ||
          e.response?.data['message'] == null ||
          e.response?.data['message'].toLowerCase().contains('token used too late') == false) {
        rethrow;
      }

      final account = await _googleSignIn.signInSilently();

      if (account != null) {
        final auth = await account.authentication;

        final idToken = auth.idToken;

        if (idToken == null) rethrow;

        await setToken(idToken);

        return await call<T>(params: params);
      }

      rethrow;
    }
  }

  /// first get from cloudflare then s3
  /// Store the ETag of the data. It will fetch and return null if the data has not changed.
  Future<Response<T>?> getCloudStorageData<T>({required String endpoint, ResponseType? responseType}) async {
    try {
      return await _getCloudData(endpoint: endpoint, baseUrl: BaseUrl.cloudflare, responseType: responseType);
    } on DioException catch (e) {
      if (e.type != DioExceptionType.unknown && e.type != DioExceptionType.badResponse) {
        rethrow;
      }

      return await _getCloudData(endpoint: endpoint, baseUrl: BaseUrl.s3);
    }
  }

  Future<Response<T>?> _getCloudData<T>({
    required String endpoint,
    required BaseUrl baseUrl,
    ResponseType? responseType,
  }) async {
    /// NOTE: don't change it if have to change then change from all place where this function is used [getCloudStorageData]

    final params = ApiParams(endpoint: endpoint, method: ApiMethod.get, baseUrl: baseUrl, responseType: responseType);

    final eTagId = endpoint;

    final storedETag = SharedPref.get(PrefKey.eTag(eTagId));

    final mergedParams = params.copyWith(
      headers: {if (storedETag != null) HttpHeaders.ifNoneMatchHeader: storedETag, ...?params.headers},
    );

    try {
      final response = await call<T>(params: mergedParams);

      final newETag = response.headers.value(HttpHeaders.etagHeader);

      if (newETag != null) {
        await SharedPref.store(PrefKey.eTag(eTagId), newETag);
      }

      return response;

      // INFO: Dio throws 304 as an exception, not a success.
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        return null;
      }

      rethrow;
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    googleSignIn: ref.read(googleSignInProvider),
    obstructiveErrorController: ref.read(obstructiveErrorControllerProvider.notifier),
  );
});
