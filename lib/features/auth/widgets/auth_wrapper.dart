import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/user/user_controller.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(userControllerProvider.select((state) => state.loading));
    final user = SharedPref.get(PrefKey.user);

    if (loading) {
      return const Loader();
    }

    if (user == null) {
      return const SignInScreen();
    }

    return child;
  }
}
