import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'dart:developer' as developer;

class YoutubeService {
  final ApiService apiService;

  YoutubeService({required this.apiService});

  final String _baseVideoInfoUrl =
      'https://youtubei.googleapis.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';
  final Map<String, dynamic> _videoInfoBasePayload = {
    "context": {
      "client": {
        "hl": "en",
        "clientName": "WEB",
        "clientVersion": "2.20210721.00.00",
        "mainAppWebInfo": {"graftUrl": ""}
      }
    },
    "videoId": ""
  };

  Future<String> getVideoMp4Url(String videoId) async {
    _videoInfoBasePayload['videoId'] = videoId;
    _videoInfoBasePayload['context']['client']['mainAppWebInfo']['graftUrl'] = '/watch?v=$videoId';

    final response = await apiService.call(
      endpoint: _baseVideoInfoUrl,
      method: Method.get,
      body: _videoInfoBasePayload,
    );

    developer.log('response: ${response.data}');

    return response.data['streamingData']['formats'][0]['url'];
  }
}

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  return YoutubeService(apiService: ref.read(apiServiceProvider));
});
