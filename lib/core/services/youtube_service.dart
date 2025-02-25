import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../shared_pref.dart';

class YoutubeService {
  static const cacheValidityPeriod = Duration(hours: 1); // Cache validity period

  Future<Map<String, String>?> _checkChachedIds(String videoId) async {
    final cachedData = await SharedPref.getCachedVideoUrl(videoId);

    if (cachedData == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(cachedData['timestamp']);

    if (DateTime.now().difference(cachedTime) > cacheValidityPeriod) return null;

    return {
      'audio': cachedData['audio'],
      'video': cachedData['video'],
    };
  }

  Future<Map<String, Map<String, String>>> listMediaVideoUrls(List<String> videoIds) async {
    final urls = <String, Map<String, String>>{};

    final yt = YoutubeExplode();

    for (final videoId in videoIds) {
      final url = await getVideoMediaUrl(videoId, yt: yt);
      urls[videoId] = url;
    }

    yt.close();
    return urls;
  }

  Future<Map<String, String>> getVideoMediaUrl(String videoId, {YoutubeExplode? yt}) async {
    // Check if the video URL is cached
    final cachedData = await _checkChachedIds(videoId);

    if (cachedData != null) {
      return cachedData;
    }

    final localYt = yt ?? YoutubeExplode();

    // Fetch new data if cache is invalid or not present
    final manifest = await localYt.videos.streamsClient.getManifest(videoId);

    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    final videoStreamInfo = manifest.videoOnly.firstWhere((element) {
      return element.container == StreamContainer.mp4 &&
          element.videoCodec.startsWith('avc1.') &&
          element.qualityLabel == '480p';
    });

    final data = {
      'audio': audioStreamInfo.url.toString(),
      'video': videoStreamInfo.url.toString(),
    };

    await SharedPref.cacheVideoUrl(videoId, data);

    if (yt == null) localYt.close();

    return data;
  }
}

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService();
});
