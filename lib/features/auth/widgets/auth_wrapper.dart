import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/user/user_controller.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final loading = ref.watch(userControllerProvider.select((state) => state.loading));
    // final userEmail = currentUser?.email; // No longer needed here
    // final progress = SharedPref.get(PrefKey.currProgress(userEmail: userEmail)); // No longer needed here
    // final lastLoggedInEmail = SharedPref.get(PrefKey.lastLoggedInEmail); // No longer needed here

    // If loading, show loader
    if (loading) {
      return const Loader();
    }

    // If user is not logged in, redirect to sign in screen
    if (currentUser == null) {
      return const SignInScreen();
    }

    // If user is logged in, show the child widget
    return child;

    /* Previous logic commented out:
    if (progress?.level != null &&
        progress!.level! > kAuthRequiredLevel &&
        lastLoggedInEmail == null) {
      return const SignInScreen();
    }

    if (currentUser == null && loading) {
      return const Loader();
    }
    */
  }
}
