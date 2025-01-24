import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';
import 'dart:developer' as developer;

abstract class IContentAPI {
  Future<List<dynamic>> getContents({int? currentLevel});
}

class ContentAPI implements IContentAPI {
  final Dio _dio;

  ContentAPI() : _dio = Dio();

  @override
  Future<List<dynamic>> getContents({int? currentLevel}) async {
    try {
      final level = currentLevel ?? 1;
      final response = await _dio.get('${dotenv.env['S3_BASE_URL']}/content/$level.json');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.data) as List<dynamic>;
        int subLevel = 1;
        return jsonList.map((json) {
          json['level'] = level;
          json['subLevel'] = subLevel;
          subLevel++;
          developer.log(json.toString());

          // Determine the type based on presence of specific fields
          if (json.containsKey('text')) {
            return SpeechExercise.fromJson(json);
          } else {
            return Video.fromJson(json);
          }
        }).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Failed to fetch contents',
      );
    } on DioException {
      // Log error or handle specific error cases
      rethrow;
    }
  }
}

final contentAPIProvider = Provider<IContentAPI>((ref) {
  return ContentAPI();
});
