import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myapp/core/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Method { get, post, put, delete }

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  final String baseUrl = 'https://1x20ei1lng.execute-api.us-east-1.amazonaws.com';

  Future<void> setToken(String token) async {
    await setToPrefs('token', token);
  }

  Future<String?> getToken() async {
    return await getFromPrefs('token');
  }

  Future<http.Response> _makeRequest({
    required String endpoint,
    required Method method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final String? token = await getToken();

    final effectiveHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };
    try {
      if (method == Method.get) {
        return await http.get(Uri.parse('$baseUrl$endpoint'), headers: effectiveHeaders);
      } else if (method == Method.post) {
        return await http.post(Uri.parse('$baseUrl$endpoint'), headers: effectiveHeaders, body: jsonEncode(body));
      } else if (method == Method.put) {
        return await http.put(Uri.parse('$baseUrl$endpoint'), headers: effectiveHeaders, body: jsonEncode(body));
      } else if (method == Method.delete) {
        return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: effectiveHeaders);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
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
    return jsonDecode(response.body);
  }
}
