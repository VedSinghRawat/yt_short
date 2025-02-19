import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:developer' as developer;

class YoutubeService {
  Future<Map<String, Uri>> getVideoMp4Url(String videoId) async {
    final yt = YoutubeExplode();
    final manifest = await yt.videos.streamsClient.getManifest(videoId);

    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();
    final videoStreamInfo = manifest.videoOnly.firstWhere((element) {
      return element.container == StreamContainer.mp4 &&
          element.videoCodec.startsWith('avc1.') &&
          element.qualityLabel == '720p';
    });

    developer.log('videoStreamInfo: ${videoStreamInfo.toString()}, videoId: $videoId');

    final data = {
      'audio': audioStreamInfo.url,
      'video': videoStreamInfo.url,
    };

    yt.close();
    return data;
  }
}

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService();
});
