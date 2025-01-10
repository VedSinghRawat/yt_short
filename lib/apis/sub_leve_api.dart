import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/models.dart';

abstract class ISubLevelAPI {
  Future<List<dynamic>> getSubLevels({int? startFromVideoId});
}

class SubLevelAPI implements ISubLevelAPI {
  // Mock video data
  final List<dynamic> _videos = [
    Video(
      id: 1,
      title: 'Flutter Basics',
      ytId: 'q30IT5IpB0Q',
      description: 'Learn the basics of Flutter',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    SpeechExercise(
      id: 1,
      ytId: 'q30IT5IpB0Q',
      textToSpeak: 'This is a Mobile',
      pauseAt: 10,
      audioUrl: 'https://example.com/audio1.mp3',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    Video(
      id: 2,
      title: 'Advanced Flutter Concepts',
      ytId: 'VRy480m4aF8',
      description: 'Deep dive into Flutter',
      createdAt: DateTime(2024, 1, 2),
      updatedAt: DateTime(2024, 1, 2),
    ),
    SpeechExercise(
      id: 2,
      ytId: 'VRy480m4aF8',
      textToSpeak: 'Flutter is powerful',
      pauseAt: 5,
      audioUrl: 'https://example.com/audio2.mp3',
      createdAt: DateTime(2024, 1, 2),
      updatedAt: DateTime(2024, 1, 2),
    ),
  ];

  @override
  Future<List<dynamic>> getSubLevels({int? startFromVideoId}) async {
    var subLevels = _videos;
    if (startFromVideoId != null) {
      return subLevels.where((video) => video.id >= startFromVideoId).toList();
    }
    return subLevels;
  }
}

final subLevelAPIProvider = Provider<ISubLevelAPI>((ref) {
  return SubLevelAPI();
});
