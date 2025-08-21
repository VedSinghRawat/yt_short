import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/services/activityLog/activity_log_service.dart';
import 'package:myapp/core/error/api_error.dart';

class ActivityLogControllerState {
  final bool loading;

  ActivityLogControllerState({this.loading = false});

  ActivityLogControllerState copyWith({bool? loading}) {
    return ActivityLogControllerState(loading: loading ?? this.loading);
  }
}

class ActivityLogController extends StateNotifier<ActivityLogControllerState> {
  final ActivityLogService activityLogService;

  ActivityLogController(this.activityLogService) : super(ActivityLogControllerState());

  Future<APIError?> syncActivityLogs(List<ActivityLog> activityLogs) async {
    state = state.copyWith(loading: true);

    final result = await activityLogService.syncActivityLogs(activityLogs);

    final error = result.fold((error) {
      developer.log('Error syncing activity logs: ${error.message}', error: error.trace);
      return error;
    }, (_) => null);

    state = state.copyWith(loading: false);
    return error;
  }
}

final activityLogControllerProvider = StateNotifierProvider<ActivityLogController, ActivityLogControllerState>((ref) {
  final activityLogService = ref.read(activityLogServiceProvider);
  return ActivityLogController(activityLogService);
});
