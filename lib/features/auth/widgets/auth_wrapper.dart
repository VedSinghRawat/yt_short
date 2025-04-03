import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/screens/sign_in_screen.dart';
import 'package:myapp/features/user/user_controller.dart';

final progressProvider = FutureProvider<Progress?>((ref) async {
  return await SharedPref.getValue(
    PrefKey.currProgress,
  );
});

class AuthWrapper extends ConsumerWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final loading = ref.watch(userControllerProvider.select((state) => state.loading));
    final progressAsyncValue = ref.watch(progressProvider);

    return progressAsyncValue.when(
      loading: () => const Loader(),
      error: (err, stack) {
        return const SignInScreen();
      },
      data: (progress) {
        if (progress?.level != null &&
            progress!.level! > kAuthRequiredLevel &&
            currentUser == null) {
          return const SignInScreen();
        }

        if (currentUser == null && loading) {
          return const Loader();
        }

        return child;
      },
    );
  }
}
