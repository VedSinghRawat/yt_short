import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context); // Get theme data
    final userState = ref.watch(userControllerProvider);
    ref.watch(langControllerProvider); // Watch for language changes
    final localUser = SharedPref.get(PrefKey.user);

    final user = userState.currentUser ?? localUser;
    final userLoading = userState.loading;
    final progress = ref.watch(uIControllerProvider.select((state) => state.currentProgress));
    final authController = ref.read(authControllerProvider.notifier);
    final authLoading = ref.watch(authControllerProvider.select((state) => state.loading));
    final userController = ref.read(userControllerProvider.notifier);
    final langController = ref.read(langControllerProvider.notifier);

    // Combine loading states
    final isLoading = authLoading || userLoading;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(langController.choose(hindi: 'प्रोफाइल', hinglish: 'Profile')),
            elevation: 0,
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.logout),
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
                        backgroundColor: const Color.fromARGB(225, 255, 255, 255),
                        child: Text(
                          user?.email.substring(0, 1).toUpperCase() ?? 'G',
                          style: TextStyle(fontSize: 40, color: theme.colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? 'Guest User',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(225, 255, 255, 255),
                          fontWeight: FontWeight.bold,
                        ),
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
                      _buildInfoRow(context, ref, 'अधिकतम सबलेवल', 'Max Sublevel Reached', '${progress.maxSubLevel}'),
                    ],
                  ),
                const SizedBox(height: 20),
                // Language Preference Card
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
                          Text(
                            langController.choose(hindi: 'भाषा', hinglish: 'Language'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          DropdownButton<PrefLang>(
                            value: user.prefLang,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            items:
                                PrefLang.values.map((PrefLang lang) {
                                  return DropdownMenuItem<PrefLang>(
                                    value: lang,
                                    child: Text(lang.name == 'hindi' ? 'हिंदी' : 'Hinglish'),
                                  );
                                }).toList(),
                            onChanged:
                                userLoading
                                    ? null
                                    : (PrefLang? newValue) async {
                                      if (newValue == null || newValue == user.prefLang) return;

                                      try {
                                        developer.log('updatePrefLang: $newValue');
                                        await userController.updatePrefLang(newValue);
                                      } catch (e) {
                                        showSnackBar(
                                          context,
                                          message: langController.choose(
                                            hindi: 'भाषा नहीं बदल सके',
                                            hinglish: 'Bhasa nahin badal sake',
                                          ),
                                          type: SnackBarType.error,
                                        );
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
                          label: Text(
                            ref
                                .read(langControllerProvider.notifier)
                                .choose(hindi: 'प्रोफाइल रीसेट करें', hinglish: 'Reset Profile'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                                    final success = await userController.resetProfile(context);

                                    if (context.mounted && success) {
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(content: Text('Profile reset successfully')),
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
            Text(
              ref.read(langControllerProvider.notifier).choose(hindi: hindiTitle, hinglish: hinglishTitle),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
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
          Text(
            ref.read(langControllerProvider.notifier).choose(hindi: labelHindi, hinglish: labelHinglish),
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700),
          ),
          Text(value, style: TextStyle(fontSize: 16, color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
