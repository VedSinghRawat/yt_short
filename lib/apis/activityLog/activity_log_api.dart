import 'package:myapp/services/api/api_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activity_log_api.g.dart';

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

@riverpod
ActivityLogAPI activityLogAPI(ref) {
  return ActivityLogAPI(ref.read(apiServiceProvider));
}
