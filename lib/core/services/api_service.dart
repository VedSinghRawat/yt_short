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
    String? customBaseUrl,
    ResponseType? responseType,
  }) = _ApiParams;
}

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final Dio _dio = Dio();
  final GoogleSignIn _googleSignIn;

  ApiService({required GoogleSignIn googleSignIn}) : _googleSignIn = googleSignIn;

  Future<void> setToken(String token) async {
    await SharedPref.setGoogleIdToken(token);
  }

  Future<String?> getToken() async {
    return await SharedPref.getGoogleIdToken();
  }

  Future<Response<T>> _makeRequest<T>({
    required ApiParams params,
  }) async {
    final String? token = await getToken();

    final effectiveHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?params.headers
    };

    try {
      final options = Options(
        method: params.method.name.toUpperCase(),
        headers: effectiveHeaders,
        responseType: params.responseType,
      );
      return await _dio.request(
        params.customBaseUrl != null
            ? '${params.customBaseUrl}${params.endpoint}'
            : '$baseUrl${params.endpoint}',
        data: params.body,
        options: options,
      );
    } catch (e) {
      if (e is DioException) {
        developer.log('DioException: ${e.response?.statusCode}', name: 'api');
        developer.log('DioException: ${e.response?.data}', name: 'api');
        rethrow;
      }
      rethrow;
    }
  }

  Future<Response<T>> call<T>({
    required ApiParams params,
  }) async {
    try {
      return await _makeRequest<T>(params: params);
    } on DioException catch (e) {
      developer
          .log('ApiError on uri ${Uri.parse('${params.customBaseUrl}${params.endpoint}')} :  $e ');
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
        return await _makeRequest<T>(params: params);
      }

      rethrow;
    }
  }

  Future<Response<T>> callWithETag<T>({
    required ApiParams params,
    required String eTagId,
    Future<T?> Function(DioException)? onCacheHit,
  }) async {
    final String? storedETag = await SharedPref.getETag(eTagId);

    final mergedParams = params.copyWith(
      headers: {
        if (storedETag != null) HttpHeaders.ifNoneMatchHeader: storedETag,
        ...?params.headers,
      },
    );

    try {
      final response = await call<T>(params: mergedParams);

      final newETag = response.headers.value(HttpHeaders.etagHeader);
      if (newETag != null) await SharedPref.storeETag(eTagId, newETag);

      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 304) {
        if (onCacheHit == null) rethrow;

        final data = await onCacheHit(e);

        return Response<T>(
          requestOptions: e.requestOptions,
          data: data,
          statusCode: 200,
        );
      }
      rethrow;
    }
  }
}
