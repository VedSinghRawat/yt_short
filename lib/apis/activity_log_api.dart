import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'dart:developer' as developer;

abstract class IActivityLogAPI {
  Future<void> syncActivityLogs(List<ActivityLog> activityLogs);
}

class ActivityLogAPI implements IActivityLogAPI {
  @override
  Future<void> syncActivityLogs(List<ActivityLog> activityLogs) async {
    try {
      final googleIdToken = await SharedPref.getGoogleIdToken();
      if (googleIdToken == null) {
        developer.log('Cannot sync: User not signed in');
        return;
      }

      final dio = Dio();
      final response = await dio.post(
        '${dotenv.env['API_BASE_URL']}/activity-log/sync',
        data: {'activityLogs': activityLogs},
        options: Options(headers: {'Authorization': 'Bearer $googleIdToken'}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync user progress: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('Error syncing user progress', error: e.toString(), stackTrace: stackTrace);
    }
  }
}

final activityLogAPIProvider = Provider<IActivityLogAPI>((ref) {
  return ActivityLogAPI();
});
