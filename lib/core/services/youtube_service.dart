import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../shared_pref.dart';
import 'dart:developer' as developer;

class YoutubeService {
  static const cacheValidityPeriod = Duration.millisecondsPerDay;

  static Future<Map<String, String>?> _getCachedYtMediaUrls(String videoId) async {
    final cachedData = await SharedPref.getCachedVideoUrl(videoId);
    if (cachedData == null) return null;

    final cachedTime = cachedData['timestamp'];
    if (DateTime.now().millisecondsSinceEpoch - cachedTime > cacheValidityPeriod) return null;

    return cachedData as Map<String, String>;
  }

  Future<Map<String, Map<String, String>>> listMediaUrls(List<String> videoIds) async {
    final results = <String, Map<String, String>>{};

    await Future.wait(
      videoIds.map((videoId) async {
        final result = await getMedia(videoId);
        if (result != null) results[videoId] = result;
      }),
    );

    return results;
  }

  static Future<Map<String, String>?> getMedia(String videoId, {YoutubeExplode? yt}) async {
    final cachedData = await _getCachedYtMediaUrls(videoId);
    if (cachedData != null) return cachedData;

    try {
      final ytClient = yt ?? YoutubeExplode();

      final manifest = await ytClient.videos.streamsClient.getManifest(videoId);

      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      final videoStreamInfo = manifest.videoOnly.firstWhere(
        (e) =>
            e.container == StreamContainer.mp4 &&
            e.videoCodec.startsWith('avc1.') &&
            e.qualityLabel == '480p',
      );

      if (yt == null) ytClient.close();

      final results = {
        'audio': audioStreamInfo.url.toString(),
        'video': videoStreamInfo.url.toString(),
      };

      await SharedPref.cacheVideoUrl(videoId, results);

      return results;
    } catch (e) {
      developer.log('Error fetching video: $videoId - $e');
    }

    return null;
  }
}

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService();
});
