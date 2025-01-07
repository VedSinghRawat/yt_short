import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';

abstract class IVideoAPI {
  Future<List<Video>> getVideos({int? startFromVideoId});
}

class VideoAPI implements IVideoAPI {
  // Mock video data
  final List<Video> _videos = [
    Video(
      id: 1,
      title: 'Introduction to Flutter',
      ytId: 'fq4N0hgOWzU',
      description: 'Learn the basics of Flutter development',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Video(
      id: 2,
      title: 'Flutter State Management',
      ytId: 'kDEflMYTFlk',
      description: 'Understanding state management in Flutter',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Video(
      id: 3,
      title: 'Flutter Navigation',
      ytId: 'nyvwx7o277U',
      description: 'Learn about navigation in Flutter',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<Video>> getVideos({int? startFromVideoId}) async {
    if (startFromVideoId != null) {
      return _videos.where((video) => video.id >= startFromVideoId).toList();
    }
    return _videos;
  }
}

final videoAPIProvider = Provider<IVideoAPI>((ref) {
  return VideoAPI();
});
