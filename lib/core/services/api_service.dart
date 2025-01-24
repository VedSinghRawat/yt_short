import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/constants/prefs.dart';
import 'package:myapp/core/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Method { get, post, put, delete }

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  final Dio _dio = Dio();

  Future<void> setToken(String token) async {
    await setToPrefs(Prefs.token, token);
  }

  Future<String?> getToken() async {
    return await getFromPrefs(Prefs.token);
  }

  Future<Response> _makeRequest({
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
        rethrow;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> call({
    required String endpoint,
    required Method method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _makeRequest(endpoint: endpoint, method: method, body: body, headers: headers);
    return response.data;
  }
}
