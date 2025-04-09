import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:myapp/core/console.dart';
import 'package:myapp/core/error/failure.dart';
import 'package:myapp/models/models.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> attemptScrollForward({
    required num level,
    required num sublevel,
    required String levelId,
  }) async {
    await _logCustomEvent(
      eventName: 'attempt_scroll_forward',
      parameters: {
        'level': level,
        'sub_level': sublevel,
        'level_id': levelId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> sublevelLoop({
    required num level,
    required num sublevel,
    required String levelId,
  }) async {
    await _logCustomEvent(
      eventName: 'level_loop',
      parameters: {
        'level': level,
        'sub_level': sublevel,
        'level_id': levelId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> exerciseRetry({
    required SpeechExercise speechExercise,
  }) async {
    await _logCustomEvent(
      eventName: 'exercise_retry',
      parameters: {
        'level': speechExercise.level,
        'sub_level': speechExercise.index,
        'level_id': speechExercise.levelId,
        'text': speechExercise.text,
        'video_filename': speechExercise.videoFilename,
        'pause_at': speechExercise.pauseAt,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> scrollBackward({
    required num fromLevel,
    required num fromSublevel,
    required num toLevel,
    required num toSublevel,
    required String fromLevelId,
    required String toLevelId,
  }) async {
    await _logCustomEvent(
      eventName: 'scroll_backward',
      parameters: {
        'from_level': fromLevel,
        'from_sublevel': fromSublevel,
        'to_level': toLevel,
        'to_sublevel': toSublevel,
        'from_level_id': fromLevelId,
        'to_level_id': toLevelId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );

      Console.log('Analytics Event: $eventName - $parameters');
    } catch (e) {
      Console.log('Analytics Event error: $eventName - $parameters');
      Console.error(Failure(message: e.toString()), StackTrace.current);
    }
  }
}
