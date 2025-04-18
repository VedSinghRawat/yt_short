import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/apis/activity_log_api.dart';
import 'package:myapp/models/activity_log/activity_log.dart';

class ActivityLogControllerState {
  final bool loading;

  ActivityLogControllerState({this.loading = false});

  ActivityLogControllerState copyWith({bool? loading}) {
    return ActivityLogControllerState(loading: loading ?? this.loading);
  }
}

class ActivityLogController extends StateNotifier<ActivityLogControllerState> {
  final IActivityLogAPI activityLogAPI;

  ActivityLogController(this.activityLogAPI) : super(ActivityLogControllerState());

  Future<void> syncActivityLogs(List<ActivityLog> activityLogs) async {
    state = state.copyWith(loading: true);
    await activityLogAPI.syncActivityLogs(activityLogs);
    state = state.copyWith(loading: false);
  }
}

final activityLogControllerProvider =
    StateNotifierProvider<ActivityLogController, ActivityLogControllerState>((ref) {
      final activityLogAPI = ref.read(activityLogAPIProvider);
      return ActivityLogController(activityLogAPI);
    });
