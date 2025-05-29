import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/core/widgets/show_confirmation_dialog.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/models.dart';
import '../auth_controller.dart';
import '../../../core/widgets/custom_app_bar.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider.select((state) => state.loading));

    return Scaffold(
      appBar: CustomAppBar(title: 'Sign In', ignoreInteractions: isLoading),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Learn English\n',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: 'With CodeYogi',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 56),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64.0),
                      child: Image.asset(
                        'assets/img/signin-baba.png', // Assuming the image is in assets/images
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                await ref.read(authControllerProvider.notifier).signInWithGoogle(context);

                                if (!context.mounted) return;

                                final user = ref.read(userControllerProvider).currentUser;

                                if (user != null) {
                                  context.go(Routes.home);
                                }
                              },
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.network(
                          'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                          height: 36,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.login);
                          },
                        ),
                      ),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                        side: BorderSide(color: Theme.of(context).colorScheme.onTertiary, width: 0.5),
                      ),
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
                if (isLoading) const Loader(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

showLevelChangeConfirmationDialog(BuildContext context, UserModel user, Ref ref) async {
  final result = await showConfirmationDialog(
    context,
    question: ref
        .read(langProvider.notifier)
        .prefLangText(
          PrefLangText(
            hindi:
                'आप पहले से Level ${user.maxLevel}, Sublevel ${user.maxSubLevel} पर हैं। क्या आप वहीं से आगे बढ़ना चाहेंगे?',
            hinglish:
                'Aap already Level ${user.maxLevel}, Sublevel ${user.maxSubLevel} par hain. Kya aap wahan se continue karna chahenge?',
          ),
        ),

    yesButtonStyle: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  await SharedPref.store(
    PrefKey.currProgress(userEmail: user.email),
    Progress(
      level: result ? user.maxLevel : null,
      subLevel: result ? user.maxSubLevel : null,
      maxLevel: user.maxLevel,
      maxSubLevel: user.maxSubLevel,
      levelId: result ? user.levelId : null,
    ),
  );
}
