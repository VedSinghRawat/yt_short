import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/loading_refresh_icon.dart';
import 'package:myapp/features/auth/auth_controller.dart';
import 'package:myapp/features/user/user_controller.dart';

class HomeScreenAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const HomeScreenAppBar({super.key});

  @override
  ConsumerState<HomeScreenAppBar> createState() => _HomeScreenAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeScreenAppBarState extends ConsumerState<HomeScreenAppBar> {
  bool _isLoading = false;

  String _getWelcomeMessage() {
    final isFirstLogin = ref.read(authControllerProvider).loginInThisSession;

    if (isFirstLogin) {
      return ref.read(langProvider.notifier).prefLangText(const PrefLangText(hindi: 'स्वागत है', hinglish: 'Welcome'));
    }

    return ref
        .read(langProvider.notifier)
        .prefLangText(const PrefLangText(hindi: 'वापस app में स्वागत है!', hinglish: 'Welcome Back!'));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final syncFailed = ref.watch(userControllerProvider.select((state) => state.syncFailed));
    final isLoggedIn = SharedPref.get(PrefKey.user) != null;

    final needsReload = currentUser?.email.isEmpty ?? true && isLoggedIn;

    return AppBar(
      title: Text(_getWelcomeMessage()),
      actions: [
        if (needsReload || syncFailed)
          LoadingRefreshIcon(
            isLoading: _isLoading,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });

              final initializeService = await ref.read(initializeServiceProvider.future);

              final isSuccess = await initializeService.initialApiCall();

              if (syncFailed) {
                await ref
                    .read(userControllerProvider.notifier)
                    .sync(currentUser?.levelId ?? '', currentUser?.subLevel ?? 0);
              }

              final progress = SharedPref.get(PrefKey.currProgress(userEmail: currentUser?.email));

              if (progress != null && progress.levelId != null && progress.subLevel != null) {
                await ref.read(userControllerProvider.notifier).sync(progress.levelId!, progress.subLevel!);
              }

              setState(() {
                _isLoading = false;
              });

              if (!context.mounted) return;

              showSnackBar(
                context,
                type: isSuccess ? SnackBarType.success : SnackBarType.error,
                message: ref
                    .read(langProvider.notifier)
                    .prefLangText(
                      isSuccess
                          ? const PrefLangText(hindi: 'डेटा सफलतापूर्वक अपडेट हो गया', hinglish: 'Data update ho gaya')
                          : const PrefLangText(hindi: 'डेटा अपडेट नहीं हो सका।', hinglish: 'Data update nahin ho saka'),
                    ),
              );
            },
          ),
        IconButton(
          onPressed: () {
            context.push(isLoggedIn ? Routes.profile : Routes.signIn);
          },
          icon: Icon(isLoggedIn ? Icons.account_circle : Icons.person_add),
        ),
      ],
    );
  }
}
