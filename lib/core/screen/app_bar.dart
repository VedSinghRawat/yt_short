import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
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
        IconButton(
          onPressed: () {
            if (isLoggedIn) {
              context.push(Routes.profile);
            } else {
              context.push(Routes.signIn);
            }
          },
          icon: isLoggedIn ? const Icon(Icons.account_circle) : const Icon(Icons.person_add),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
