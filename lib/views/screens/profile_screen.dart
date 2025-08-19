import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/controllers/auth/auth_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context); // Get theme data
    final userState = ref.watch(userControllerProvider);
    final currentLang = ref.watch(langControllerProvider); // Watch for language changes
    final localUser = SharedPref.get(PrefKey.user);

    final user = userState.currentUser ?? localUser;
    final userLoading = userState.loading;
    final progress = ref.watch(uIControllerProvider.select((state) => state.currentProgress));
    final authController = ref.read(authControllerProvider.notifier);
    final authLoading = ref.watch(authControllerProvider.select((state) => state.loading));
    final userController = ref.read(userControllerProvider.notifier);

    // Combine loading states
    final isLoading = authLoading || userLoading;

    // Initialize responsiveness service
    final responsivenessService = ResponsivenessService(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const LangText.heading(hindi: 'प्रोफाइल', hinglish: 'Profile'),
            elevation: 0,
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  iconSize: responsivenessService.getResponsiveValues(mobile: 24.0, tablet: 28.0, largeTablet: 32.0),
                  constraints: BoxConstraints(
                    minWidth: responsivenessService.getResponsiveValues(mobile: 48.0, tablet: 56.0, largeTablet: 64.0),
                    minHeight: responsivenessService.getResponsiveValues(mobile: 48.0, tablet: 56.0, largeTablet: 64.0),
                  ),
                  color: theme.colorScheme.error,
                  onPressed: () async {
                    await authController.signOut(context);
                    if (context.mounted) {
                      context.go(Routes.signIn);
                    }
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color.fromARGB(225, 255, 255, 255),
                            child: LangText.bodyText(
                              text: user?.email.substring(0, 1).toUpperCase() ?? 'G',
                              style: TextStyle(fontSize: 40, color: theme.colorScheme.secondary),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LangText.headingText(
                            text: user?.email ?? 'Guest User',
                            style: const TextStyle(color: Color.fromARGB(225, 255, 255, 255)),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (progress != null && progress.level != null)
                      _buildInfoCard(
                        context,
                        ref,
                        hindiTitle: 'प्रगति विवरण',
                        hinglishTitle: 'Progress Overview',
                        children: [
                          _buildInfoRow(context, ref, 'लेवल', 'Level', '${progress.level}'),
                          _buildInfoRow(context, ref, 'सबलेवल', 'Sublevel', '${progress.subLevel}'),
                          _buildInfoRow(context, ref, 'अधिकतम लेवल', 'Max Level Reached', '${progress.maxLevel}'),
                          _buildInfoRow(
                            context,
                            ref,
                            'अधिकतम सबलेवल',
                            'Max Sublevel Reached',
                            '${progress.maxSubLevel}',
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (user != null)
                      _buildInfoCard(
                        context,
                        ref,
                        hindiTitle: 'अतिरिक्त',
                        hinglishTitle: 'Extras',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              LangText.body(
                                hindi: 'भाषा',
                                hinglish: 'Language',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              DropdownButton<PrefLang>(
                                value: user.prefLang,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                items:
                                    PrefLang.values.map((PrefLang lang) {
                                      return DropdownMenuItem<PrefLang>(
                                        value: lang,
                                        child: LangText.bodyText(text: lang.name == 'hindi' ? 'हिंदी' : 'Hinglish'),
                                      );
                                    }).toList(),
                                onChanged:
                                    userLoading
                                        ? null
                                        : (PrefLang? newValue) async {
                                          if (newValue == null || newValue == user.prefLang) return;
                                          try {
                                            await userController.updatePrefLang(newValue);
                                          } catch (e) {
                                            if (context.mounted) {
                                              showSnackBar(
                                                context,
                                                message: choose(
                                                  hindi: 'भाषा नहीं बदल सके',
                                                  hinglish: 'Bhasa nahin badal sake',
                                                  lang: currentLang,
                                                ),
                                                type: SnackBarType.error,
                                              );
                                            }
                                          }
                                        },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.restart_alt),
                              label: const LangText.body(
                                hindi: 'प्रोफाइल रीसेट करें',
                                hinglish: 'Reset Profile',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              ),
                              onPressed:
                                  isLoading
                                      ? null
                                      : () async {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        final success = await userController.resetProfile(context);
                                        if (context.mounted && success) {
                                          scaffoldMessenger.showSnackBar(
                                            const SnackBar(
                                              content: LangText.bodyText(text: 'Profile reset successfully'),
                                            ),
                                          );
                                        }
                                      },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading) const Center(child: Loader()),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    WidgetRef ref, {
    required String hindiTitle,
    required String hinglishTitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context); // Get theme data

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.colorScheme.primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LangText.heading(
              hindi: hindiTitle,
              hinglish: hinglishTitle,
              style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w700),
            ),
            Divider(
              color: theme.colorScheme.onPrimary.withValues(alpha: .5),
              height: 20,
            ), // Adjust divider color for contrast
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, WidgetRef ref, String labelHindi, String labelHinglish, String value) {
    final theme = Theme.of(context); // Get theme data

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LangText.body(
            hindi: labelHindi,
            hinglish: labelHinglish,
            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700),
          ),
          LangText.bodyText(
            text: value,
            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
