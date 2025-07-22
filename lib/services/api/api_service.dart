import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/controllers/obstructiveError/obstructive_error_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/shared_pref.dart';
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/services/googleSignIn/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  final Dio _dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) {
        return status! < AppConstants.kMaxHttpStatusCode;
      },
    ),
  );
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

    final options = Options(
      method: params.method.name.toUpperCase(),
      headers: effectiveHeaders,
      responseType: params.responseType,
      contentType: 'application/json',
    );

    final response = await _dio.request<T>(baseUrl, data: params.body, options: options);

    if (response.statusCode == AppConstants.obstructiveErrorStatus) {
      _obstructiveErrorController.showObstructiveError((response.data as dynamic)['content']);

      return response;
    }

    if (!(response.data == null ||
        response.data is! Map<String, dynamic> ||
        (response.data as dynamic)['message'] == null ||
        (response.data as dynamic)['message'].toLowerCase().contains('token used too late') == false)) {
      final account = await _googleSignIn.signInSilently();

      if (account != null) {
        final auth = await account.authentication;

        final idToken = auth.idToken;

        if (idToken == null) throw APIError(message: 'Token is null');

        await setToken(idToken);

        return await call<T>(params: params);
      }
    }

    if (response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
      String message = '';
      try {
        final data = response.data as Map<String, dynamic>;
        message = data['message'];
      } catch (e) {
        message = 'Something went wrong';
      }

      developer.log('Error in ApiService.call: $message');
      throw APIError(message: message, trace: StackTrace.current);
    }

    return response;
  }

  /// first get from cloudflare then s3
  /// Store the ETag of the data. It will fetch and return null if the data has not changed.
  Future<Response<T>?> getCloudStorageData<T>({required String endpoint, ResponseType? responseType}) async {
    try {
      return await _getCloudData<T>(endpoint: endpoint, baseUrl: BaseUrl.cloudflare, responseType: responseType);
    } catch (e) {
      try {
        return await _getCloudData(endpoint: endpoint, baseUrl: BaseUrl.s3, responseType: responseType);
      } catch (e) {
        return null;
      }
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

    final response = await call<T>(params: mergedParams);
    if (response.statusCode == 304) {
      return null;
    }

    final newETag = response.headers.value(HttpHeaders.etagHeader);

    if (newETag != null) {
      await SharedPref.store(PrefKey.eTag(eTagId), newETag);
    }

    return response;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(
    googleSignIn: ref.read(googleSignInProvider),
    obstructiveErrorController: ref.read(obstructiveErrorControllerProvider.notifier),
  );
});
