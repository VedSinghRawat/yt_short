import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/core/services/google_sign_in.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_service.freezed.dart';

enum ApiMethod { get, post, put, delete }

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(googleSignIn: ref.read(googleSignInProvider));
});

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

  bool get isS3 => name == 's3';

  @override
  String toString() => '$name: $url';
}

class ApiService {
  final Dio _dio = Dio();
  final GoogleSignIn _googleSignIn;

  ApiService({required GoogleSignIn googleSignIn}) : _googleSignIn = googleSignIn;

  Future<void> setToken(String token) async {
    await SharedPref.storeValue(
      PrefKey.googleIdToken,
      token,
    );
  }

  Future<String?> getToken() async {
    return await SharedPref.getValue(
      PrefKey.googleIdToken,
    );
  }

  Future<Response<T>> call<T>({
    required ApiParams params,
  }) async {
    final String? token = await getToken();

    final effectiveHeaders = {
      'Content-Type': 'application/json',
      if (token != null && params.baseUrl?.isS3 != true) 'Authorization': 'Bearer $token',
      ...?params.headers
    };

    try {
      final options = Options(
        method: params.method.name.toUpperCase(),
        headers: effectiveHeaders,
        responseType: params.responseType,
        contentType: 'application/json',
      );
      return await _dio.request(
        params.baseUrl != null
            ? '${params.baseUrl?.url}${params.endpoint}'
            : '${BaseUrl.backend.url}${params.endpoint}',
        data: params.body,
        options: options,
      );
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) >= 400) {
        developer.log('ApiError on uri ${Uri.parse('${params.baseUrl}${params.endpoint}')} :  $e ');
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

  /// Store the ETag of the data. It will fetch and return null if the data has not changed.
  Future<Response<T>?> getCloudStorageData<T>({
    required ApiParams params,
  }) async {
    final eTagId = params.endpoint;

    final storedETag = await SharedPref.getRawValue(
      PrefKey.eTagKey(
        eTagId,
      ),
    );

    final mergedParams = params.copyWith(
      headers: {
        if (storedETag != null) HttpHeaders.ifNoneMatchHeader: storedETag,
        ...?params.headers,
      },
    );

    try {
      final response = await call<T>(params: mergedParams);

      final newETag = response.headers.value(HttpHeaders.etagHeader);

      if (newETag != null) {
        await SharedPref.storeRawValue(
            PrefKey.eTagKey(
              eTagId,
            ),
            newETag);
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
