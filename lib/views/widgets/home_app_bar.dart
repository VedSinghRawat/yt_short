import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/services/initialize/initialize_service.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';
import 'package:myapp/core/shared_pref.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/views/widgets/loading_refresh_icon.dart';
import 'package:myapp/controllers/user/user_controller.dart';
import 'package:myapp/controllers/ui/ui_controller.dart';
import 'package:myapp/views/widgets/lang_text.dart';

class HomeAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  ConsumerState<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends ConsumerState<HomeAppBar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final syncFailed = ref.watch(userControllerProvider.select((state) => state.syncFailed));

    final isLoggedIn = SharedPref.get(PrefKey.user) != null;
    final needsReload = currentUser?.email.isEmpty ?? true && isLoggedIn;

    final progress = ref.watch(uIControllerProvider.select((state) => state.currentProgress));
    final titleText = 'Level ${progress?.level ?? 1} Sublevel ${progress?.subLevel ?? 1}';

    final responsiveness = ResponsivenessService(context);
    final titleFontSize = responsiveness.getResponsiveValues(mobile: 18, tablet: 22, largeTablet: 28);

    return AppBar(
      title: LangText.heading(hindi: titleText, hinglish: titleText, style: TextStyle(fontSize: titleFontSize)),
      actions: [
        if (needsReload || syncFailed)
          LoadingRefreshIcon(
            isLoading: _isLoading,
            onTap: () async {
              setState(() {
                _isLoading = true;
              });

              final initializeService = await ref.read(initializeServiceProvider.future);

              final error = await initializeService.initialApiCall();
              final isSuccess = error == null; // null means success, APIError means failure

              if (syncFailed) {
                final progress = ref.read(uIControllerProvider).currentProgress;

                if (progress != null && progress.levelId != null && progress.subLevel != null) {
                  await ref.read(userControllerProvider.notifier).sync(progress.levelId!, progress.subLevel!);
                }
              }

              setState(() {
                _isLoading = false;
              });

              if (!context.mounted) return;

              showSnackBar(
                context,
                type: isSuccess ? SnackBarType.success : SnackBarType.error,
                message: choose(
                  hindi: isSuccess ? 'डेटा सफलतापूर्वक अपडेट हो गया' : 'डेटा अपडेट नहीं हो सका।',
                  hinglish: isSuccess ? 'Data update ho gaya' : 'Data update nahin ho saka',
                  lang: ref.read(langControllerProvider),
                ),
              );
            },
          ),
        IconButton(
          onPressed: () {
            context.push(isLoggedIn ? Routes.profile : Routes.signIn);
          },
          icon: Icon(isLoggedIn ? Icons.account_circle : Icons.person_add),
          iconSize: responsiveness.getResponsiveValues(mobile: 32, tablet: 36, largeTablet: 40),
        ),
      ],
    );
  }
}
