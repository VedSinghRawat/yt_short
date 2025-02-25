import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';

abstract class IContentAPI {
  Future<List<Content>> listByLevel(int level);
}

class ContentAPI implements IContentAPI {
  ContentAPI();

  @override
  Future<List<Content>> listByLevel(int level) async {
    final dio = Dio();
    final response = await dio.get('${dotenv.env['S3_BASE_URL']}/levels/$level.json');

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch content for level $level");
    }

    final List<dynamic> jsonList = (response.data['sub_levels']);
    int subLevel = 1;

    return jsonList.map((json) {
      json['level'] = level;
      json['subLevel'] = subLevel;
      subLevel++;

      if (json.containsKey('text')) {
        return Content(null, SpeechExercise.fromJson(json));
      } else if (json.containsKey('ytId')) {
        return Content(Video.fromJson(json), null);
      } else {
        throw Exception("Invalid content type");
      }
    }).toList();
  }
}

final contentAPIProvider = Provider<IContentAPI>((ref) {
  return ContentAPI();
});
