import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/services/api_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/activity_log/activity_log.dart';

abstract class IActivityLogAPI {
  Future<void> syncActivityLogs(List<ActivityLog> activityLogs);
}

class ActivityLogAPI implements IActivityLogAPI {
  final ApiService _apiService;

  ActivityLogAPI(this._apiService);

  @override
  Future<void> syncActivityLogs(List<ActivityLog> activityLogs) async {
    final googleIdToken = SharedPref.get(PrefKey.googleIdToken);

    if (googleIdToken == null) return;

    await _apiService.call(
      params: ApiParams(body: {'activityLogs': activityLogs}, method: ApiMethod.post, endpoint: '/activity-log/sync'),
    );
  }
}

final activityLogAPIProvider = Provider<IActivityLogAPI>((ref) {
  return ActivityLogAPI(ref.read(apiServiceProvider));
});
