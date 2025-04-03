import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/core/widgets/show_confirmation_dialog.dart';
import 'package:myapp/features/sublevel/sublevel_controller.dart';
import 'package:myapp/features/user/user_controller.dart';
import '../auth_controller.dart';
import '../../../core/widgets/custom_app_bar.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider.select((state) => state.loading));

    log('sign in screen', name: 'sign in screen');

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Sign In',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLoading) const Loader(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Text(
                          "Welcome to",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "CodeYogi's English Course",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle(context);

                            if (!context.mounted) return;

                            final user = ref.read(userControllerProvider).currentUser;

                            if (user != null) {
                              context.go(Routes.home);
                            }
                          },
                    icon: Image.network(
                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.login);
                      },
                    ),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

showLevelChangeConfirmationDialog(
    BuildContext context, int maxLevel, int maxSubLevel, SublevelController sublevelController) {
  return showConfirmationDialog(
    context,
    question:
        'We notice that you are already at Level $maxLevel, Sublevel $maxSubLevel. Do you want to continue from there?',
    onResult: (result) async {
      if (result) {
        await SharedPref.copyWith(
          PrefKey.currProgress,
          Progress(
            level: maxLevel,
            subLevel: maxSubLevel,
          ),
        );
      }

      await SharedPref.copyWith(
        PrefKey.currProgress,
        Progress(
          maxLevel: maxLevel,
          maxSubLevel: maxSubLevel,
        ),
      );

      await sublevelController.handleFetchSublevels();
    },
    yesButtonStyle: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
