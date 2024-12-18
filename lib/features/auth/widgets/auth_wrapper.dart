import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    switch (authState) {
      case AuthState.authenticated:
        return child;
      case AuthState.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthState.error:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('An error occurred'),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(authControllerProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case AuthState.initial:
      case AuthState.unauthenticated:
        return const SignInScreen();
    }
  }
}
