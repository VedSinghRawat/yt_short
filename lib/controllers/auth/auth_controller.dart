import 'dart:developer' as developer;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/activityLog/activity_log.controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/error/api_error.dart';
import 'dart:async';
import '../../services/auth/auth_service.dart';
import '../user/user_controller.dart';

part 'auth_controller.freezed.dart';
part 'auth_controller.g.dart';

@freezed
class AuthControllerState with _$AuthControllerState {
  const factory AuthControllerState({@Default(false) bool loading}) = _AuthControllerState;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  late final authService = ref.read(authServiceProvider);

  @override
  AuthControllerState build() => const AuthControllerState(loading: false);

  Future<bool> signInWithGoogle() async {
    if (state.loading) return false;
    state = state.copyWith(loading: true);

    final userController = ref.read(userControllerProvider.notifier);

    final signInResult = await authService.signInWithGoogle();

    bool needsLanguagePrompt = false;

    await signInResult.fold(
      (error) {
        // Error is handled by the calling code
      },
      (userDTO) async {
        try {
          needsLanguagePrompt = userDTO.prefLang == null;

          // Update user model *before* potentially showing dialog
          final user = userController.userFromDTO(userDTO);

          await SharedPref.store(PrefKey.doneToday, user.doneToday);

          final syncResult = await authService.syncCyId();
          syncResult.fold(
            (error) {
              developer.log('Error syncing cyId: ${error.message}');
            },
            (_) {
              // Sync successful
            },
          );

          await userController.updateCurrentUser(user);
        } catch (e, stackTrace) {
          developer.log('Error in AuthController.signInWithGoogle', error: e.toString(), stackTrace: stackTrace);
          await userController.removeCurrentUser();
        }
      },
    );

    state = state.copyWith(loading: false);
    return needsLanguagePrompt;
  }

  Future<APIError?> syncCyId() async {
    state = state.copyWith(loading: true);

    final user = ref.read(userControllerProvider.notifier).getUser();
    if (user == null) {
      state = state.copyWith(loading: false);
      return null;
    }

    final syncResult = await authService.syncCyId();

    final error = syncResult.fold((error) {
      return error;
    }, (_) => null);

    state = state.copyWith(loading: false);
    return error;
  }

  Future<APIError?> signOut() async {
    if (state.loading) return APIError(message: 'Already processing', trace: StackTrace.current);
    state = state.copyWith(loading: true);

    final userController = ref.read(userControllerProvider.notifier);
    final activityLogController = ref.read(activityLogControllerProvider.notifier);

    final user = ref.read(userControllerProvider.notifier).getUser();

    if (user != null) {
      final activityLogs = SharedPref.get(PrefKey.activityLogs);

      if (activityLogs != null) {
        try {
          final error = await activityLogController.syncActivityLogs(activityLogs);
          if (error != null) {
            return error;
          }
          await SharedPref.removeValue(PrefKey.activityLogs);
        } catch (e, stackTrace) {
          developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
          return APIError(message: e.toString(), trace: stackTrace);
        }
      }

      final signOutResult = await authService.signOut();

      final error = signOutResult.fold((error) {
        return error;
      }, (_) => null);

      if (error != null) {
        state = state.copyWith(loading: false);
        return error;
      }

      await userController.removeCurrentUser();
      await Future.delayed(Duration.zero); // Allow UI to update
    }

    state = state.copyWith(loading: false);
    return null; // Success
  }
}
