import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/supabase/supabase_config.dart';
import 'package:myapp/models/models.dart';

abstract class IVideoAPI {
  Future<List<Video>> getVideos({int? startFromVideoId});
}

class VideoAPI implements IVideoAPI {
  @override
  Future<List<Video>> getVideos({int? startFromVideoId}) async {
    var query = SupabaseConfig.client.from('videos').select();

    if (startFromVideoId != null) {
      // Get videos with IDs greater than equal to the last viewed video ID
      query = query.gte('id', startFromVideoId);
    }

    final response = await query;

    final videos = List<Map<String, dynamic>>.from(response).map((video) => Video.fromJson(video)).toList();

    return videos;
  }
}

final videoAPIProvider = Provider<IVideoAPI>((ref) {
  return VideoAPI();
});
