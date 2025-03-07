import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';

abstract class ISublevelAPI {
  Future<List<Sublevel>> listPublishedByLevel(int level);
  Future<Map<String, dynamic>?> getUnpulishedSublevel(int level);
  Future<List<Sublevel>> listByLevel(int level);
}

class SublevelAPI implements ISublevelAPI {
  SublevelAPI();

  @override
  Future<List<Sublevel>> listPublishedByLevel(int level) async {
    final jsonList = await _getLevel(level);

    int subLevel = 0;

    final sublevels = jsonList.map((json) {
      subLevel++;
      return jsonToSublevel(json, level, subLevel);
    }).toList();

    return sublevels;
  }

  Future<List<dynamic>> _getLevel(int level) async {
    final dio = Dio();
    final response = await dio.get('${dotenv.env['S3_BASE_URL']}/levels/$level.json');

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch sublevel for level $level");
    }

    final List<dynamic> jsonList = (response.data['sub_levels']);

    return jsonList;
  }

  Sublevel jsonToSublevel(json, int level, int subLevel) {
    json['level'] = level;
    json['subLevel'] = subLevel;

    if (json.containsKey('text')) {
      return Sublevel(null, SpeechExercise.fromJson(json));
    } else if (json.containsKey('ytId')) {
      return Sublevel(Video.fromJson(json), null);
    } else {
      throw Exception("Invalid sublevel type");
    }
  }

  @override
  Future<Map<String, dynamic>?> getUnpulishedSublevel(int level) async {
    final dio = Dio();
    try {
      final response = await dio.get(
          '${dotenv.env['S3_BASE_URL']}/levels/${dotenv.env['VITE_AWS_RANDOM_KEY']}_$level.json');

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch unpublished sublevel for level $level");
      }
      return response.data;
    } catch (e) {
      developer.log('Error fetching unpublished level $level', error: e);
      return null;
    }
  }

  @override
  Future<List<Sublevel>> listByLevel(int level) async {
    try {
      final results = await Future.wait([
        _getLevel(level),
        getUnpulishedSublevel(level),
      ]);

      final jsonList = results[0] as List<dynamic>;
      final jsonListLength = jsonList.length;
      final unpublished = results[1] as Map<String, dynamic>? ?? {};

      final List<Sublevel> sublevels = [];

      for (var i = 0; i < jsonListLength + unpublished.length; i++) {
        sublevels.add(
          jsonToSublevel(
            unpublished.containsKey(i.toString())
                ? unpublished[i.toString()]
                : jsonList.removeAt(0),
            level,
            i + 1,
          ),
        );
      }

      return sublevels;
    } on DioException catch (e) {
      developer.log('Error fetching sublevel for level $level', error: e);

      rethrow;
    }
  }
}

final sublevelAPIProvider = Provider<ISublevelAPI>((ref) {
  return SublevelAPI();
});
