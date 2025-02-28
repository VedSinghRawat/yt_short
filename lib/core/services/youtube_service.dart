import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../shared_pref.dart';
import 'dart:developer' as developer;

class YoutubeService {
  static const cacheValidityPeriod = Duration(hours: 1);

  Future<Map<String, String>?> _checkCachedIds(String videoId) async {
    final cachedData = await SharedPref.getCachedVideoUrl(videoId);
    if (cachedData == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(cachedData['timestamp']);
    if (DateTime.now().difference(cachedTime) > cacheValidityPeriod) return null;

    return {'audio': cachedData['audio'], 'video': cachedData['video']};
  }

  Future<Map<String, Map<String, String>>> listMediaVideoUrls(List<String> videoIds) async {
    final cachedResults = <String, Map<String, String>>{};

    final cacheChecks = await Future.wait(videoIds.map(_checkCachedIds));

    final uncachedVideoIds = <String>[];
    for (int i = 0; i < videoIds.length; i++) {
      if (cacheChecks[i] != null) {
        cachedResults[videoIds[i]] = cacheChecks[i]!;
      } else {
        uncachedVideoIds.add(videoIds[i]);
      }
    }

    if (uncachedVideoIds.isEmpty) return cachedResults;

    final receivePort = ReceivePort();
    await Isolate.spawn(_fetchVideosInBackground, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;

    final responsePort = ReceivePort();
    sendPort.send([uncachedVideoIds, responsePort.sendPort]);

    final fetchedResults = await responsePort.first as Map<String, Map<String, String>>;
    cachedResults.addAll(fetchedResults);

    for (final videoId in fetchedResults.keys) {
      await SharedPref.cacheVideoUrl(videoId, fetchedResults[videoId]!);
    }

    return cachedResults;
  }

  static void _fetchVideosInBackground(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    await for (final message in receivePort) {
      final List<String> videoIds = message[0] as List<String>;
      final SendPort responsePort = message[1] as SendPort;
      final yt = YoutubeExplode();

      final results = <String, Map<String, String>>{};

      await Future.wait(videoIds.map((videoId) => getMedia(videoId, yt: yt, results: results)));

      yt.close();
      responsePort.send(results);
    }
  }

  static Future<void> getMedia(String videoId,
      {YoutubeExplode? yt, Map<String, Map<String, String>>? results}) async {
    try {
      final localYt = yt ?? YoutubeExplode();

      final manifest = await localYt.videos.streamsClient.getManifest(videoId);

      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      final videoStreamInfo = manifest.videoOnly.firstWhere(
        (e) =>
            e.container == StreamContainer.mp4 &&
            e.videoCodec.startsWith('avc1.') &&
            e.qualityLabel == '480p',
      );

      if (yt == null) localYt.close();

      results![videoId] = {
        'audio': audioStreamInfo.url.toString(),
        'video': videoStreamInfo.url.toString(),
      };
    } catch (e) {
      developer.log('Error fetching video: $videoId - $e');
    }
  }
}

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService();
});
