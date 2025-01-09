import '../models/video/video.dart';
import '../models/speech_exercise/speech_exercise.dart';

// App Version Constants
const String kRequiredAppVersion = '1.0.0'; // Minimum version required to run the app
const String kSuggestedAppVersion = '1.1.0'; // Version recommended for optimal experience

final kDummySubLevels = [
  Video(
    id: 1,
    title: 'Introduction to Flutter',
    ytId: 'dxYFWQs_XrY',
    description: 'Learn the basics of Flutter development',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  ),
  SpeechExercise(
    id: 1,
    ytId: 'dxYFWQs_XrY',
    textToSpeak: 'Flutter is amazing',
    pauseAt: 30,
    audioUrl: 'https://example.com/audio1.mp3',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  ),
  Video(
    id: 2,
    title: 'Advanced Flutter Concepts',
    ytId: 'hL7pkX1Pfko',
    description: 'Deep dive into Flutter',
    createdAt: DateTime(2024, 1, 2),
    updatedAt: DateTime(2024, 1, 2),
  ),
  SpeechExercise(
    id: 2,
    ytId: 'hL7pkX1Pfko',
    textToSpeak: 'Flutter is powerful',
    pauseAt: 45,
    audioUrl: 'https://example.com/audio2.mp3',
    createdAt: DateTime(2024, 1, 2),
    updatedAt: DateTime(2024, 1, 2),
  ),
];
