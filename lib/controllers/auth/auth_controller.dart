import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/activityLog/activity_log.controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/shared_pref.dart';
import 'dart:async';
import '../../services/auth/auth_service.dart';
import '../../core/utils.dart';
import '../user/user_controller.dart';

part 'auth_controller.freezed.dart';
part 'auth_controller.g.dart';

@freezed
class AuthControllerState with _$AuthControllerState {
  const factory AuthControllerState({@Default(false) bool loading, @Default(null) String? error}) =
      _AuthControllerState;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  bool _isProcessing = false;
  late final authService = ref.watch(authServiceProvider);

  @override
  AuthControllerState build() => const AuthControllerState(loading: false);

  Future<bool> signInWithGoogle() async {
    if (_isProcessing) return false;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    final userController = ref.read(userControllerProvider.notifier);

    final signInResult = await authService.signInWithGoogle();

    bool needsLanguagePrompt = false;

    await signInResult.fold(
      (error) {
        state = state.copyWith(error: error.message);
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
          state = state.copyWith(error: e.toString());
        }
      },
    );

    _isProcessing = false;
    state = state.copyWith(loading: false);
    return needsLanguagePrompt;
  }

  Future<void> syncCyId() async {
    state = state.copyWith(error: null, loading: true);

    final user = ref.read(userControllerProvider).currentUser;
    if (user == null) {
      state = state.copyWith(loading: false);
      return;
    }

    final syncResult = await authService.syncCyId();

    syncResult.fold(
      (error) {
        state = state.copyWith(error: error.message);
      },
      (_) {
        state = state.copyWith(error: null);
      },
    );

    state = state.copyWith(loading: false);
  }

  Future<void> signOut(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    final userController = ref.read(userControllerProvider.notifier);
    final activityLogController = ref.read(activityLogControllerProvider.notifier);

    final user = ref.read(userControllerProvider).currentUser;

    if (user != null) {
      final activityLogs = SharedPref.get(PrefKey.activityLogs);

      if (activityLogs != null) {
        try {
          await activityLogController.syncActivityLogs(activityLogs);
          await SharedPref.removeValue(PrefKey.activityLogs);
        } catch (e, stackTrace) {
          developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
        }
      }

      final signOutResult = await authService.signOut();

      await signOutResult.fold(
        (error) {
          if (context.mounted) {
            showSnackBar(context, message: error.message, type: SnackBarType.error);
          }
        },
        (_) async {
          await userController.removeCurrentUser();
        },
      );

      await Future.delayed(Duration.zero); // Allow UI to update
    }

    _isProcessing = false;
    state = state.copyWith(loading: false);
  }
}
