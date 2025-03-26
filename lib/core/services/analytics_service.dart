import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking
  Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    );
  }

  // Authentication events
  Future<void> logSignUp({String method = 'email'}) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _logCustomEvent(
      eventName: 'signup',
      parameters: {'method': method},
    );
  }

  Future<void> logLogin({String method = 'email'}) async {
    await _analytics.logLogin(loginMethod: method);
    await _logCustomEvent(
      eventName: 'login',
      parameters: {'method': method},
    );
  }

  Future<void> logLogout() async {
    await _logCustomEvent(eventName: 'logout');
    await resetUserProperties();
  }

  // Progress events
  Future<void> logLevelComplete(int level, {String? levelType}) async {
    await _logCustomEvent(
      eventName: 'level_complete',
      parameters: {
        'level_number': level,
        'level_type': levelType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Engagement events
  Future<void> logScrollForward(String screenName, String itemId) async {
    await _logCustomEvent(
      eventName: 'scroll_forward',
      parameters: {
        'screen': screenName,
        'item_id': itemId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> logScrollBackward(String screenName, String itemId) async {
    await _logCustomEvent(
      eventName: 'scroll_backward',
      parameters: {
        'screen': screenName,
        'item_id': itemId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Exercise/activity events
  Future<void> logExerciseRetry(
    String exerciseId, {
    int attemptNumber = 1,
    String? reason,
  }) async {
    await _logCustomEvent(
      eventName: 'exercise_retry',
      parameters: {
        'exercise_id': exerciseId,
        'attempt_number': attemptNumber,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // User properties
  Future<void> setUserProperties({
    String? userId,
    String? userRole,
    int? levelReached,
  }) async {
    if (userId != null) {
      await _analytics.setUserId(id: userId);
    }
    if (userRole != null) {
      await _analytics.setUserProperty(name: 'user_role', value: userRole);
    }
    if (levelReached != null) {
      await _analytics.setUserProperty(
        name: 'level_reached',
        value: levelReached.toString(),
      );
    }
  }

  Future<void> resetUserProperties() async {
    await _analytics.setUserId(id: null);
    await _analytics.resetAnalyticsData();
  }

  // Private helper method for custom events
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
      developer.log('Analytics Event: $eventName - $parameters');
      return true;
    }());
  }
}
