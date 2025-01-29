import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import '../auth_controller.dart';
import '../screens/sign_in_screen.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    SharedPref.getCurrProgress().then((value) {
      if (value?['level'] != null &&
          value?['level']! > kAuthRequiredLevel &&
          authState.authState == AuthState.unauthenticated) {
        return const SignInScreen();
      }

      if (authState.authState == AuthState.initial) return const Loader();

      return child;
    });

    return const Loader();
  }
}
