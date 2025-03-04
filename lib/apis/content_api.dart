import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';

abstract class IContentAPI {
  Future<List<Content>> listPublishedByLevel(int level);
  Future<Map<String, dynamic>?> getUnpulishedSublevel(int level);
  Future<List<Content>> listByLevel(int level);
}

class ContentAPI implements IContentAPI {
  ContentAPI();

  @override
  Future<List<Content>> listPublishedByLevel(int level) async {
    final jsonList = await _getLevel(level);

    int subLevel = 0;

    final contents = jsonList.map((json) {
      subLevel++;
      return jsonToContent(json, level, subLevel);
    }).toList();

    return contents;
  }

  Future<List<dynamic>> _getLevel(int level) async {
    final dio = Dio();
    final response = await dio.get('${dotenv.env['S3_BASE_URL']}/levels/$level.json');

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch content for level $level");
    }

    final List<dynamic> jsonList = (response.data['sub_levels']);

    return jsonList;
  }

  Content jsonToContent(json, int level, int subLevel) {
    json['level'] = level;
    json['subLevel'] = subLevel;

    if (json.containsKey('text')) {
      return Content(null, SpeechExercise.fromJson(json));
    } else if (json.containsKey('ytId')) {
      return Content(Video.fromJson(json), null);
    } else {
      throw Exception("Invalid content type");
    }
  }

  @override
  Future<Map<String, dynamic>?> getUnpulishedSublevel(int level) async {
    final dio = Dio();
    try {
      final response = await dio.get(
          '${dotenv.env['S3_BASE_URL']}/levels/${dotenv.env['VITE_AWS_RANDOM_KEY']}_$level.json');

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch unpublished content for level $level");
      }
      return response.data;
    } catch (e) {
      developer.log('Error fetching unpublished level $level', error: e);
      return null;
    }
  }

  @override
  Future<List<Content>> listByLevel(int level) async {
    try {
      final results = await Future.wait([
        _getLevel(level),
        getUnpulishedSublevel(level),
      ]);

      final jsonList = results[0] as List<dynamic>;
      final unpublished = results[1] as Map<String, dynamic>;

      final List<Content> contents = [];

      for (var i = 0; i < jsonList.length + unpublished.length; i++) {
        contents.add(
          jsonToContent(
            unpublished.containsKey(i.toString())
                ? unpublished[i.toString()]
                : jsonList.removeAt(0),
            level,
            i + 1,
          ),
        );
      }

      return contents;
    } on DioException catch (e) {
      developer.log('Error fetching content for level $level', error: e);

      rethrow;
    }
  }
}

final contentAPIProvider = Provider<IContentAPI>((ref) {
  return ContentAPI();
});
