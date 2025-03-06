import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/util_classes.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../shared_pref.dart';
import 'dart:developer' as developer;

class YoutubeService {
  final cacheValidityPeriod = Duration.millisecondsPerDay;

  Future<Media?> _getCachedYtMediaUrls(String videoId) async {
    final cachedData = await SharedPref.getCachedVideoUrl(videoId);
    if (cachedData == null) return null;

    // Extract expiration times from URLs
    int audioExpiry = _getExpiryFromUrl(cachedData.audio);
    int videoExpiry = _getExpiryFromUrl(cachedData.video);

    // Get the latest expiry time
    int earliestExpiry = audioExpiry > videoExpiry ? videoExpiry : audioExpiry;

    // Check if URL will expire in less than 10 minutes
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int tenMinutesInSeconds = Duration.secondsPerMinute * 10;

    if (earliestExpiry - currentTime < tenMinutesInSeconds) return null;

    return cachedData;
  }

  int _getExpiryFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String? expireParam = uri.queryParameters['expire'];
      if (expireParam != null) {
        return int.parse(expireParam);
      }
    } catch (e) {
      developer.log('Error parsing URL expiry: $e');
    }

    return 0;
  }

  Future<Map<String, Media>> listMediaUrls(List<String> videoIds) async {
    final results = <String, Media>{};

    await Future.wait(
      videoIds.map((videoId) async {
        final result = await handleGetMediaUrls(videoId);
        if (result != null) results[videoId] = result;
      }),
    );

    return results;
  }

  Future<Media> _getMediaUrls(Map<String, dynamic> params) async {
    final videoId = params['videoId'] as String;
    final yt = params['yt'] as YoutubeExplode?;

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

    final results = Media(
      audio: audioStreamInfo.url.toString(),
      video: videoStreamInfo.url.toString(),
    );

    return results;
  }

  Future<Media?> handleGetMediaUrls(String videoId, {YoutubeExplode? yt}) async {
    final cachedData = await _getCachedYtMediaUrls(videoId);
    if (cachedData != null) return cachedData;

    try {
      final results = await compute(_getMediaUrls, {'videoId': videoId, 'yt': yt});

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
