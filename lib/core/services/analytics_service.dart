import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:myapp/core/console.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Engagement events
  Future<void> attemptScrollForward(num level, num sublevel) async {
    await _logCustomEvent(
      eventName: 'attempt_scroll_forward',
      parameters: {
        'level': level,
        'sublevel': sublevel,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> levelLoop(num level, num sublevel) async {
    await _logCustomEvent(
      eventName: 'level_loop',
      parameters: {
        'level': level,
        'sublevel': sublevel,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> exerciseRetry(
    String exerciseId, {
    int attemptNumber = 1,
  }) async {
    await _logCustomEvent(
      eventName: 'exercise_retry',
      parameters: {
        'exercise_id': exerciseId,
        'attempt_number': attemptNumber,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // User properties
  Future<void> scrollBackward(num fromLevel, num fromSublevel, num toLevel, num toSublevel) async {
    await _logCustomEvent(
      eventName: 'scroll_backward',
      parameters: {
        'from_level': fromLevel,
        'from_sublevel': fromSublevel,
        'to_level': toLevel,
        'to_sublevel': toSublevel,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters as Map<String, Object>?,
    );

    // For debugging - print events in development
    assert(() {
      Console.log('Analytics Event: $eventName - $parameters');
      return true;
    }());
  }
}
