import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/activityLog/activity_log.controller.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/views/screens/sign_in_screen.dart';
import 'package:myapp/models/user/user.dart'; // Import User model for PrefLang
import 'dart:async';
import '../../apis/auth/auth_api.dart';
import '../../core/utils.dart';
import '../user/user_controller.dart';

part 'auth_controller.freezed.dart';
part 'auth_controller.g.dart';

@freezed
class AuthControllerState with _$AuthControllerState {
  const factory AuthControllerState({
    @Default(false) bool loading,
    @Default(null) String? error,
    @Default(false) bool loginInThisSession,
  }) = _AuthControllerState;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  bool _isProcessing = false;

  @override
  AuthControllerState build() => const AuthControllerState(loading: false, loginInThisSession: false);

  Future<void> signInWithGoogle(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    try {
      final authAPI = ref.read(authAPIProvider);
      final userController = ref.read(userControllerProvider.notifier);

      final userDTO = await authAPI.signInWithGoogle();

      if (userDTO == null) {
        return;
      }

      bool needsLanguagePrompt = userDTO.prefLang == null; // Example check

      // Update user model *before* potentially showing dialog
      final user = userController.updateCurrentUser(userDTO);

      await SharedPref.store(PrefKey.doneToday, user.doneToday);
      await authAPI.syncCyId();

      await Future.delayed(Duration.zero); // Yield control to UI

      // Ask for language preference if needed
      if (needsLanguagePrompt && context.mounted) {
        final chosenLang = await showDialog<PrefLang>(
          context: context,
          barrierDismissible: false, // User must choose
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.2), width: 2.0),
              ),
              title: const Text('आपकी पसंदीदा भाषा क्या है? / Aapki pasandida bhasha kya hai?'),
              content: const Text(
                'वह भाषा चुनें जिसमें आप सबसे अधिक सहज हैं। / Vo bhasha chunen jis mein aap sabse adhik sahaj hain.',
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(dialogContext).colorScheme.onPrimary),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(PrefLang.hindi),
                  child: Text(
                    'हिन्दी',
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(dialogContext).colorScheme.onSecondary),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(PrefLang.hinglish),
                  child: Text(
                    'Hinglish',
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        final finalLang = chosenLang ?? PrefLang.hinglish;
        await userController.updatePrefLang(finalLang);
      }

      // Continue with existing logic (progress check, etc.)
      final progress = SharedPref.get(PrefKey.currProgress());
      await SharedPref.store(PrefKey.user, user);

      final level = progress?.maxLevel ?? 1;
      final subLevel = progress?.maxSubLevel ?? 1;

      if (context.mounted && (user.maxLevel > level || (user.maxLevel == level && user.maxSubLevel > subLevel))) {
        await showLevelChangeConfirmationDialog(context, user, ref);
      } else if (progress != null) {
        SharedPref.store(PrefKey.currProgress(userEmail: user.email), progress);
      }

      state = state.copyWith(loginInThisSession: true);
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signInWithGoogle', error: e.toString(), stackTrace: stackTrace);
      final userController = ref.read(userControllerProvider.notifier);
      userController.removeCurrentUser();
      if (context.mounted) {
        showSnackBar(context, message: e.toString(), type: SnackBarType.error);
      }
    } finally {
      _isProcessing = false;
      state = state.copyWith(loading: false);
    }
  }

  Future<void> syncCyId() async {
    try {
      state = state.copyWith(error: null, loading: true);

      final user = ref.read(userControllerProvider).currentUser;

      if (user == null) {
        state = state.copyWith(loading: false);
        return;
      }

      final authAPI = ref.read(authAPIProvider);
      await authAPI.syncCyId();

      state = state.copyWith(error: null);
    } on DioException catch (e) {
      state = state.copyWith(error: parseError(e.type, ref.read(langControllerProvider)));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    try {
      final userController = ref.read(userControllerProvider.notifier);
      final activityLogController = ref.read(activityLogControllerProvider.notifier);

      final authAPI = ref.read(authAPIProvider);

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

        await authAPI.signOut();

        userController.removeCurrentUser();
        await Future.delayed(Duration.zero); // Allow UI to update
      }
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        showSnackBar(context, message: e.toString(), type: SnackBarType.error);
      }
    } finally {
      _isProcessing = false;
      state = state.copyWith(loading: false);
    }
  }
}
