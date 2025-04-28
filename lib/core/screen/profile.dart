import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/auth_controller.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/user/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userControllerProvider);
    final localUser = SharedPref.get(PrefKey.user);
    final theme = Theme.of(context); // Get theme data

    final user = userState.currentUser ?? localUser;

    final userLoading = userState.loading;
    final progress = SharedPref.get(PrefKey.currProgress(userEmail: user?.email));
    final authController = ref.read(authControllerProvider.notifier);
    final authLoading = ref.watch(authControllerProvider).loading;
    final userController = ref.read(userControllerProvider.notifier);
    // Combine loading states
    final isLoading = authLoading || userLoading;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              ref.read(langProvider.notifier).prefLangText(const PrefLangText(hindi: 'प्रोफाइल', hinglish: 'Profile')),
              // No explicit color needed, AppBar uses theme's onSurface implicitly
            ),
            elevation: 0,
            // Background color will be inherited from the theme's AppBarTheme or ColorScheme.surface
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  color: theme.colorScheme.error, // Use error color from theme
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
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.9), // Use onPrimary from theme
                        child: Text(
                          user?.email.substring(0, 1).toUpperCase() ?? 'G',
                          style: TextStyle(
                            fontSize: 40,
                            color: theme.colorScheme.secondary,
                          ), // Use primary color from theme
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? 'Guest User',
                        style: TextStyle(
                          fontSize: 20,
                          color: theme.colorScheme.onPrimary, // Use onPrimary color from theme
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Language Preference Card
                if (user != null)
                  _buildInfoCard(
                    context,
                    title: ref
                        .read(langProvider.notifier)
                        .prefLangText(const PrefLangText(hindi: 'अपनी भाषा चुनें', hinglish: 'Language Preference')),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ref
                                .read(langProvider.notifier)
                                .prefLangText(const PrefLangText(hindi: 'भाषा', hinglish: 'Language')),
                            style: const TextStyle(fontSize: 16),
                          ),
                          DropdownButton<PrefLang>(
                            value: user.prefLang,
                            items:
                                PrefLang.values.map((PrefLang lang) {
                                  return DropdownMenuItem<PrefLang>(
                                    value: lang,
                                    child: Text(lang.name == 'hindi' ? 'हिंदी' : 'Hinglish'),
                                  );
                                }).toList(),
                            onChanged:
                                userLoading // Disable dropdown while loading
                                    ? null
                                    : (PrefLang? newValue) {
                                      if (newValue != null && newValue != user.prefLang) {
                                        userController.updatePrefLang(newValue).then((success) {
                                          if (!success && context.mounted) {
                                            showSnackBar(
                                              context,
                                              message: ref
                                                  .read(langProvider.notifier)
                                                  .prefLangText(
                                                    const PrefLangText(
                                                      hindi: 'भाषा नहीं बदल सके',
                                                      hinglish: 'Bhasa nahin badal sake',
                                                    ),
                                                  ),
                                              type: SnackBarType.error,
                                            );
                                          }
                                        });
                                      }
                                    },
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                if (progress != null && progress.level != null)
                  _buildInfoCard(
                    context,
                    title: ref
                        .read(langProvider.notifier)
                        .prefLangText(const PrefLangText(hindi: 'प्रगति विवरण', hinglish: 'Progress Overview')),
                    children: [
                      _buildInfoRow(
                        context,
                        ref
                            .read(langProvider.notifier)
                            .prefLangText(const PrefLangText(hindi: 'लेवल', hinglish: 'Level')),
                        '${progress.level}',
                      ),
                      _buildInfoRow(
                        context,
                        ref
                            .read(langProvider.notifier)
                            .prefLangText(const PrefLangText(hindi: 'सबलेवल', hinglish: 'Sublevel')),
                        '${progress.subLevel}',
                      ),
                      _buildInfoRow(
                        context,
                        ref
                            .read(langProvider.notifier)
                            .prefLangText(const PrefLangText(hindi: 'अधिकतम लेवल', hinglish: 'Max Level Reached')),
                        '${progress.maxLevel}',
                      ),
                      _buildInfoRow(
                        context,
                        ref
                            .read(langProvider.notifier)
                            .prefLangText(const PrefLangText(hindi: 'अधिकतम सबलेवल', hinglish: 'Max Sublevel Reached')),
                        '${progress.maxSubLevel}',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (isLoading) const Center(child: Loader()),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required List<Widget> children}) {
    final theme = Theme.of(context); // Get theme data
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.colorScheme.primary, // Use primary color for card background
      // Card uses theme's cardTheme.color (defaults to colorScheme.surface) and elevation
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary, // Use secondary color for title
              ),
            ),
            Divider(
              color: theme.colorScheme.onPrimary.withOpacity(0.5),
              height: 20,
            ), // Adjust divider color for contrast
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context); // Get theme data
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onPrimary.withOpacity(0.7), // Use onPrimary for contrast
            ),
          ),
          Text(
            value,
            style: TextStyle(
              // Use onSurface color from theme
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimary, // Use onPrimary for contrast
            ),
          ),
        ],
      ),
    );
  }
}
