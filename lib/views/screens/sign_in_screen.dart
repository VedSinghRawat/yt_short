import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/util_types/progress.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/views/widgets/language_preference_dialog.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/show_confirmation_dialog.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/models/models.dart';
import '../../controllers/auth/auth_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import '../widgets/custom_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:myapp/views/widgets/lang_text.dart';

final Widget googleLogo = SvgPicture.asset(
  'assets/svgs/google-logo.svg',
  semanticsLabel: 'Google Logo',
  width: 20,
  height: 20,
);

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  Future<void> _handlePostSignIn(BuildContext context, WidgetRef ref) async {
    final user = ref.read(userControllerProvider.notifier).getUser();
    if (user == null) return;
    final progress = ref.read(uIControllerProvider).currentProgress;
    final uiController = ref.read(uIControllerProvider.notifier);

    final level = progress?.maxLevel ?? 1;
    final subLevel = progress?.maxSubLevel ?? 1;

    if (isLevelAfter(level, subLevel, user.maxLevel, user.maxSubLevel) ||
        isLevelEqual(level, subLevel, user.maxLevel, user.maxSubLevel)) {
      return;
    }

    final result = await showConfirmationDialog(
      context,
      question: choose(
        hindi:
            'आप पहले से Level ${user.maxLevel}, Sublevel ${user.maxSubLevel} पर हैं। क्या आप वहीं से आगे बढ़ना चाहेंगे?',
        hinglish:
            'Aap already Level ${user.maxLevel}, Sublevel ${user.maxSubLevel} par hain. Kya aap wahan se continue karna chahenge?',
        lang: ref.read(langControllerProvider),
      ),

      yesButtonStyle: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    await uiController.storeProgress(
      Progress(
        level: result ? user.maxLevel : level,
        subLevel: result ? user.maxSubLevel : subLevel,
        maxLevel: user.maxLevel,
        maxSubLevel: user.maxSubLevel,
        levelId: result ? user.levelId : null,
      ),
      userEmail: user.email,
    );
  }

  Future<void> showLanguagePreferenceDialog(BuildContext context, WidgetRef ref) async {
    final chosenLang = await showDialog<PrefLang>(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (BuildContext dialogContext) {
        return const LanguagePreferenceDialog();
      },
    );

    final finalLang = chosenLang ?? PrefLang.hinglish;
    await ref.read(userControllerProvider.notifier).updatePrefLang(finalLang);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(authControllerProvider.select((state) => state.loading)) ||
        ref.watch(userControllerProvider.select((state) => state.loading));

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
                    Column(
                      children: [
                        LangText.heading(
                          hindi: 'अंग्रेजी सीखें',
                          hinglish: 'Learn English',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        LangText.heading(
                          hindi: 'CodeYogi के साथ',
                          hinglish: 'With CodeYogi',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
                                final router = GoRouter.of(context);

                                final needsLanguagePrompt =
                                    await ref.read(authControllerProvider.notifier).signInWithGoogle();

                                if (!context.mounted) return;

                                if (ref.read(userControllerProvider.notifier).getUser() == null) {
                                  return;
                                }

                                if (needsLanguagePrompt && context.mounted) {
                                  await showLanguagePreferenceDialog(context, ref);
                                }

                                if (context.mounted) {
                                  await _handlePostSignIn(context, ref);
                                }

                                router.go(Routes.home);
                              },
                      icon: Padding(padding: const EdgeInsets.only(right: 8.0), child: googleLogo),
                      label: const LangText.body(
                        hindi: 'Google से साइन इन करें',
                        hinglish: 'Sign in with Google',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
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
