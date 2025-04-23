import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/user/user_controller.dart';

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(userControllerProvider.select((state) => state.currentUser)) ??
        SharedPref.get(PrefKey.user);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        context.go(Routes.signIn);
      });

      return const Loader();
    }

    return child;
  }
}
