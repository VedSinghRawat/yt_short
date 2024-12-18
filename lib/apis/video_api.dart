import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/supabase/supabase_config.dart';
import 'package:myapp/models/models.dart';

abstract class IVideoAPI {
  Future<List<Video>> getVideos();
}

class VideoAPI implements IVideoAPI {
  @override
  Future<List<Video>> getVideos() async {
    final response = await SupabaseConfig.client.from('videos').select().order('created_at');

    final videos = List<Map<String, dynamic>>.from(response).map((video) => Video.fromJson(video)).toList();

    return videos;
  }
}

final videoAPIProvider = Provider<IVideoAPI>((ref) {
  return VideoAPI();
});
