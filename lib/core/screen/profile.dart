import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/auth_controller.dart';
import 'package:myapp/features/user/user_controller.dart';
import 'package:myapp/models/user/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userControllerProvider);
    final user = userState.currentUser;
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
            title: const Text('Profile'),
            elevation: 0,
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  color: Colors.red,
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.email.substring(0, 1).toUpperCase() ?? 'G',
                          style: TextStyle(fontSize: 40, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.email ?? 'Guest User',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user?.role == UserRole.admin ? 'Admin' : 'Student',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                    title: 'Language Preference',
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dialogue Language', style: TextStyle(fontSize: 16)),
                          DropdownButton<PrefLang>(
                            value: user.prefLang,
                            items:
                                PrefLang.values.map((PrefLang lang) {
                                  return DropdownMenuItem<PrefLang>(
                                    value: lang,
                                    child: Text(lang.name == 'hindi' ? 'Hindi' : 'Hinglish'),
                                  );
                                }).toList(),
                            onChanged:
                                userLoading // Disable dropdown while loading
                                    ? null
                                    : (PrefLang? newValue) {
                                      if (newValue != null && newValue != user.prefLang) {
                                        userController.updatePrefLang(newValue).then((success) {
                                          if (!success && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Failed to update language preference',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
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
                    title: 'Progress Overview',
                    children: [
                      _buildInfoRow('Current Level', '${progress.level}'),
                      _buildInfoRow('Current Sublevel', '${progress.subLevel}'),
                      _buildInfoRow('Max Level Reached', '${progress.maxLevel}'),
                      _buildInfoRow('Max Sublevel Reached', '${progress.maxSubLevel}'),
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
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
