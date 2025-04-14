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
    final currentUser = ref.watch(
      userControllerProvider.select((state) => state.currentUser),
    );
    final loading = ref.watch(
      userControllerProvider.select((state) => state.loading),
    );
    final userEmail = currentUser?.email;
    final progress = SharedPref.get(PrefKey.currProgress(userEmail: userEmail));
    final lastLoggedInEmail = SharedPref.get(PrefKey.lastLoggedInEmail);

    if (progress?.level != null &&
        progress!.level! > kAuthRequiredLevel &&
        lastLoggedInEmail == null) {
      return const SignInScreen();
    }

    if (currentUser == null && loading) {
      return const Loader();
    }

    return child;
  }
}
