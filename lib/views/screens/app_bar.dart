import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/services/initialize/initialize_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/views/widgets/loading_refresh_icon.dart';
import 'package:myapp/controllers/auth/auth_controller.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/controllers/sublevel/sublevel_controller.dart';

class HomeScreenAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const HomeScreenAppBar({super.key});

  @override
  ConsumerState<HomeScreenAppBar> createState() => _HomeScreenAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeScreenAppBarState extends ConsumerState<HomeScreenAppBar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final syncFailed = ref.watch(userControllerProvider.select((state) => state.syncFailed));
    final isFirstLogin = ref.watch(authControllerProvider.select((state) => state.loginInThisSession));
    final langController = ref.watch(langControllerProvider.notifier);

    final isLoggedIn = SharedPref.get(PrefKey.user) != null;
    final needsReload = currentUser?.email.isEmpty ?? true && isLoggedIn;

    final showAppBar = ref.watch(sublevelControllerProvider.select((state) => state.showAppBar));

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: showAppBar ? 0 : -kToolbarHeight,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: showAppBar ? 1.0 : 0.0,
            child: AppBar(
              title: Text(
                isFirstLogin
                    ? langController.choose(hindi: 'स्वागत है', hinglish: 'Welcome')
                    : langController.choose(hindi: 'वापस app में स्वागत है!', hinglish: 'Welcome Back!'),
              ),
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
                            .read(langControllerProvider.notifier)
                            .choose(
                              hindi: isSuccess ? 'डेटा सफलतापूर्वक अपडेट हो गया' : 'डेटा अपडेट नहीं हो सका।',
                              hinglish: isSuccess ? 'Data update ho gaya' : 'Data update nahin ho saka',
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
            ),
          ),
        ),
      ],
    );
  }
}
