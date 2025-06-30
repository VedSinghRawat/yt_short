import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/controllers/activityLog/activity_log.controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/views/screens/sign_in_screen.dart';
import 'package:myapp/models/user/user.dart';
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

  Future<void> signInWithGoogle(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    final userController = ref.read(userControllerProvider.notifier);

    final signInResult = await authService.signInWithGoogle();

    await signInResult.fold(
      (error) {
        state = state.copyWith(error: error.message);
        if (context.mounted) {
          showSnackBar(context, message: error.message, type: SnackBarType.error);
        }
      },
      (userDTO) async {
        try {
          bool needsLanguagePrompt = userDTO.prefLang == null;

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
                    side: BorderSide(
                      color: Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.2),
                      width: 2.0,
                    ),
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
          await userController.updateCurrentUser(user);

          final level = progress?.maxLevel ?? 1;
          final subLevel = progress?.maxSubLevel ?? 1;

          if (context.mounted && (user.maxLevel > level || (user.maxLevel == level && user.maxSubLevel > subLevel))) {
            await showLevelChangeConfirmationDialog(context, user, ref);
          } else if (progress != null) {
            await SharedPref.store(PrefKey.currProgress(userEmail: user.email), progress);
          }
        } catch (e, stackTrace) {
          developer.log('Error in AuthController.signInWithGoogle', error: e.toString(), stackTrace: stackTrace);
          await userController.removeCurrentUser();
          if (context.mounted) {
            showSnackBar(context, message: e.toString(), type: SnackBarType.error);
          }
        }
      },
    );

    _isProcessing = false;
    state = state.copyWith(loading: false);
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
