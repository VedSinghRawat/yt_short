import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:myapp/apis/activityLog/activity_log_api.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/error/api_error.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/models/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activity_log_service.g.dart';

class ActivityLogService {
  final IActivityLogAPI activityLogAPI;
  final PrefLang lang;

  ActivityLogService(this.activityLogAPI, this.lang);

  FutureEither<void> syncActivityLogs(List<ActivityLog> activityLogs) async {
    try {
      await activityLogAPI.syncActivityLogs(activityLogs);
      return right(null);
    } on DioException catch (e) {
      return left(APIError(message: parseError(e.type, lang), trace: e.stackTrace, dioExceptionType: e.type));
    } catch (e) {
      return left(APIError(message: e.toString(), trace: StackTrace.current));
    }
  }
}

@riverpod
ActivityLogService activityLogService(Ref ref) {
  final activityLogAPI = ref.read(activityLogAPIProvider);
  final lang = ref.read(langControllerProvider);
  return ActivityLogService(activityLogAPI, lang);
}
