import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/user/user_controller.dart';

final progressProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await SharedPref.getCurrProgress();
});

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userController = ref.watch(userControllerProvider);
    final progressAsyncValue = ref.watch(progressProvider);

    return progressAsyncValue.when(
      loading: () => const Loader(),
      error: (err, stack) {
        return const SignInScreen();
      },
      data: (progress) {
        if (progress?['level'] != null &&
            progress?['level']! > kAuthRequiredLevel &&
            userController.currentUser == null) {
          return const SignInScreen();
        }

        if (userController.currentUser == null && userController.loading) {
          return const Loader();
        }

        return child;
      },
    );
  }
}
