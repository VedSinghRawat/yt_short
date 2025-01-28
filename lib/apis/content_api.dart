import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/models/models.dart';
import 'dart:developer' as developer;

abstract class IContentAPI {
  Future<List<Content>> listByLevel(int level);
}

class ContentAPI implements IContentAPI {
  final ApiService _apiService;

  ContentAPI({required ApiService apiService}) : _apiService = apiService;

  @override
  Future<List<Content>> listByLevel(int level) async {
    final response = await _apiService.call(endpoint: '/content/$level.json', method: Method.get);

    final List<dynamic> jsonList = jsonDecode(response.data) as List<dynamic>;
    int subLevel = 1;
    return jsonList.map((json) {
      json['level'] = level;
      json['subLevel'] = subLevel;
      subLevel++;

      // Determine the type based on presence of specific fields
      if (json.containsKey('text')) {
        return Content(speechExercise: SpeechExercise.fromJson(json));
      } else {
        return Content(video: Video.fromJson(json));
      }
    }).toList();
  }
}

final contentAPIProvider = Provider<IContentAPI>((ref) {
  return ContentAPI(apiService: ref.read(apiServiceProvider));
});
