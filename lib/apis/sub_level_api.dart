import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';

abstract class ISubLevelAPI {
  Future<List<SubLevel>> listByLevel(int level);
}

class SubLevelAPI implements ISubLevelAPI {
  SubLevelAPI();

  @override
  Future<List<SubLevel>> listByLevel(int level) async {
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

  SubLevel jsonToSublevel(Map<String, dynamic> json, int level, int subLevel) {
    json['level'] = level;
    json['subLevel'] = subLevel;

    if (json.containsKey('text')) {
      return SubLevel(null, SpeechExercise.fromJson(json));
    } else if (json.containsKey('ytId')) {
      return SubLevel(Video.fromJson(json), null);
    } else {
      throw Exception("Invalid sublevel type");
    }
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI();
});
