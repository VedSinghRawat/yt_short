import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

enum Method { get, post, put, delete }

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final Dio _dio = Dio();

  Future<void> setToken(String token) async {
    await SharedPref.setGoogleIdToken(token);
  }

  Future<String?> getToken() async {
    return await SharedPref.getGoogleIdToken();
  }

  Future<Response<T>> _makeRequest<T>({
    required String endpoint,
    required Method method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final String? token = await getToken();

    final effectiveHeaders = {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token', ...?headers};

    try {
      final options = Options(method: method.name.toUpperCase(), headers: effectiveHeaders);
      return await _dio.request('$baseUrl$endpoint', data: body, options: options);
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
    required Method method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return await _makeRequest<T>(endpoint: endpoint, method: method, body: body, headers: headers);
  }
}
