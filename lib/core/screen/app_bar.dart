import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/features/auth/auth_controller.dart';
import 'package:myapp/features/user/user_controller.dart';

class HomeScreenAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeScreenAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn =
        ref.watch(userControllerProvider.select((state) => state.currentUser))?.email.isNotEmpty ??
            false;

    return AppBar(
      title: const Text('Learn English'),
      actions: [
        !isLoggedIn
            ? IconButton(
                onPressed: () {
                  context.push(Routes.signIn);
                },
                icon: const Icon(Icons.account_circle),
              )
            : PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                onSelected: (value) {
                  if (value == 'signout') {
                    ref.read(authControllerProvider.notifier).signOut(context);
                    context.go(Routes.signIn);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
