import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/models/activity_log/activity_log.dart';
import 'package:myapp/services/activityLog/activity_log_service.dart';

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

  Future<void> syncActivityLogs(List<ActivityLog> activityLogs) async {
    state = state.copyWith(loading: true);

    final result = await activityLogService.syncActivityLogs(activityLogs);

    result.fold(
      (error) {
        developer.log('Error syncing activity logs: ${error.message}', error: error.trace);
        state = state.copyWith(loading: false);
      },
      (_) {
        state = state.copyWith(loading: false);
      },
    );
  }
}

final activityLogControllerProvider = StateNotifierProvider<ActivityLogController, ActivityLogControllerState>((ref) {
  final activityLogService = ref.read(activityLogServiceProvider);
  return ActivityLogController(activityLogService);
});
