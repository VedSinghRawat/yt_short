import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/core/services/google_sign_in.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

enum ApiMethod { get, post, put, delete }

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(googleSignIn: ref.read(googleSignInProvider));
});

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
    required String endpoint,
    required ApiMethod method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? customBaseUrl,
  }) async {
    final String? token = await getToken();

    final effectiveHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers
    };

    try {
      final options = Options(method: method.name.toUpperCase(), headers: effectiveHeaders);
      return await _dio.request(
          customBaseUrl != null ? '$customBaseUrl$endpoint' : '$baseUrl$endpoint',
          data: body,
          options: options);
    } catch (e) {
      if (e is DioException) {
        // Handle Dio specific errors if needed
        developer.log('DioException: ${e.response?.statusCode}', name: 'api');
        developer.log('DioException: ${e.response?.data}', name: 'api');
        rethrow;
      }
      rethrow;
    }
  }

  Future<Response<T>> call<T>({
    required String endpoint,
    required ApiMethod method,
    Map<String, dynamic>? body,
    String? customBaseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      return await _makeRequest<T>(
          endpoint: endpoint,
          method: method,
          body: body,
          headers: headers,
          customBaseUrl: customBaseUrl);
    } on DioException catch (e) {
      developer.log('DioException: ${e.response}');
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
        return await _makeRequest<T>(
            endpoint: endpoint, method: method, body: body, headers: headers);
      }

      rethrow;
    }
  }
}
