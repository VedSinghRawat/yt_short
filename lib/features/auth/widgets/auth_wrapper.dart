import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'dart:developer' as developer;

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userController = ref.watch(userControllerProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: SharedPref.getCurrProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loader();
        }

        final progress = snapshot.data;

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
