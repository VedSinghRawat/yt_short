import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'dart:developer' as developer;

abstract class IActivityLogAPI {
  Future<void> syncActivityLogs(List<ActivityLog> activityLogs);
}

class ActivityLogAPI implements IActivityLogAPI {
  final ApiService _apiService;

  ActivityLogAPI(this._apiService);

  @override
  Future<void> syncActivityLogs(List<ActivityLog> activityLogs) async {
    try {
      final googleIdToken = await SharedPref.getGoogleIdToken();
      if (googleIdToken == null) {
        developer.log('Cannot sync: User not signed in');
        return;
      }

      await _apiService.call(
        method: Method.post,
        endpoint: '/activity-log/sync',
        body: {'activityLogs': activityLogs},
      );
    } catch (e, stackTrace) {
      developer.log('activity_log_api:', error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final activityLogAPIProvider = Provider<IActivityLogAPI>((ref) {
  return ActivityLogAPI(ref.read(apiServiceProvider));
});
