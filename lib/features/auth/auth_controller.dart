import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'dart:developer' as developer;
import '../../apis/auth_api.dart';
import '../../core/utils.dart';
import '../user/user_controller.dart';
import 'package:myapp/models/user/user.dart'; // Import User model for PrefLang
import 'dart:async';

part 'auth_controller.g.dart';

class AuthControllerState {
  final bool loading;
  final String? error;

  AuthControllerState({required this.loading, this.error});

  AuthControllerState copyWith({bool? loading, String? error}) {
    return AuthControllerState(loading: loading ?? this.loading, error: error ?? this.error);
  }
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  // Internal flag to prevent overlapping requests.
  bool _isProcessing = false;

  @override
  AuthControllerState build() {
    return AuthControllerState(loading: false);
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    if (_isProcessing) return;
    _isProcessing = true;
    state = state.copyWith(loading: true);

    try {
      final authAPI = ref.read(authAPIProvider);
      final userController = ref.read(userControllerProvider.notifier);
      final sublevelController = ref.read(sublevelControllerProvider.notifier);

      final userDTO = await authAPI.signInWithGoogle();
      if (userDTO == null) {
        // Handle case where sign in might be cancelled or fail before getting DTO
        _isProcessing = false;
        state = state.copyWith(loading: false);
        return;
      }

      // Check if language preference needs to be set
      // Assuming PrefLang.hinglish is the default and needs confirmation
      // Or if backend sends null initially, adjust the check accordingly
      bool needsLanguagePrompt = userDTO.prefLang == PrefLang.hinglish; // Example check

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
              title: const Text('Choose Dialogue Language'),
              content: const Text('Select your preferred language for dialogue translations.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hindi'),
                  onPressed: () => Navigator.of(dialogContext).pop(PrefLang.hindi),
                ),
                TextButton(
                  child: const Text('Hinglish'),
                  onPressed: () => Navigator.of(dialogContext).pop(PrefLang.hinglish),
                ),
              ],
            );
          },
        );

        // If user somehow dismissed dialog without choosing (though barrierDismissible=false)
        // or if dialog returns null, default to hinglish and save it.
        final finalLang = chosenLang ?? PrefLang.hinglish;
        await userController.updatePrefLang(finalLang);
      }

      // Continue with existing logic (progress check, etc.)
      final progress = SharedPref.get(PrefKey.currProgress());
      await SharedPref.store(PrefKey.user, user);

      final level = progress?.maxLevel ?? 1;
      final subLevel = progress?.maxSubLevel ?? 1;

      if (context.mounted &&
          (user.maxLevel > level || (user.maxLevel == level && user.maxSubLevel > subLevel))) {
        await showLevelChangeConfirmationDialog(context, user);
      } else {
        SharedPref.store(PrefKey.currProgress(userEmail: user.email), progress);
      }

      await sublevelController.fetchSublevels();
    } catch (e, stackTrace) {
      developer.log(
        'Error in AuthController.signInWithGoogle',
        error: e.toString(),
        stackTrace: stackTrace,
      );
      final userController = ref.read(userControllerProvider.notifier);
      userController.removeCurrentUser();
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
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
      state = state.copyWith(error: parseError(e.type));
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

      final authAPI = ref.read(authAPIProvider);

      final user = ref.read(userControllerProvider).currentUser;

      if (user != null) {
        await userController.sync(user.levelId, user.subLevel);
        await authAPI.signOut();
        userController.removeCurrentUser();
        await Future.delayed(Duration.zero); // Allow UI to update
      }
    } catch (e, stackTrace) {
      developer.log('Error in AuthController.signOut', error: e.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      _isProcessing = false;
      state = state.copyWith(loading: false);
    }
  }
}
