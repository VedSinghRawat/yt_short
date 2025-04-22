import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/controllers/lang_notifier.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/core/widgets/loading_refresh_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final isLoggedIn = SharedPref.get(PrefKey.user) != null;

    final needsReload = currentUser?.email.isEmpty ?? true && isLoggedIn;

    return AppBar(
      title: Text(
        ref
            .read(langProvider.notifier)
            .prefLangText(const PrefLangText(hindi: 'अंग्रेजी सीखें', hinglish: 'English Sikho')),
      ),
      actions: [
        if (needsReload)
          LoadingRefreshIcon(
            isLoading: _isLoading,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });

              final initializeService = await ref.read(initializeServiceProvider.future);

              final isSuccess = await initializeService.initialApiCall();

              final progress = SharedPref.get(PrefKey.currProgress(userEmail: currentUser?.email));

              if (progress != null && progress.levelId != null && progress.subLevel != null) {
                await ref
                    .read(userControllerProvider.notifier)
                    .sync(progress.levelId!, progress.subLevel!);
              }

              setState(() {
                _isLoading = false;
              });

              if (!context.mounted) return;

              showSnackBar(
                context,
                ref
                    .read(langProvider.notifier)
                    .prefLangText(
                      isSuccess
                          ? const PrefLangText(
                            hindi: 'डेटा सफलतापूर्वक अपडेट हो गया',
                            hinglish: 'Data updated successfully',
                          )
                          : const PrefLangText(
                            hindi: 'डेटा अपडेट नहीं हो सका।',
                            hinglish: 'Data update nahin ho saka',
                          ),
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
