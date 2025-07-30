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

class AnimatedAppBar extends ConsumerStatefulWidget {
  const AnimatedAppBar({super.key});

  @override
  ConsumerState<AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends ConsumerState<AnimatedAppBar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userControllerProvider.select((state) => state.currentUser));
    final syncFailed = ref.watch(userControllerProvider.select((state) => state.syncFailed));

    final isLoggedIn = SharedPref.get(PrefKey.user) != null;
    final needsReload = currentUser?.email.isEmpty ?? true && isLoggedIn;

    final isAppBarVisible = ref.watch(uIControllerProvider.select((state) => state.isAppBarVisible));

    final progress = ref.watch(uIControllerProvider.select((state) => state.currentProgress));
    final titleText = 'Level ${progress?.level ?? 1} Sublevel ${progress?.subLevel ?? 1}';

    final responsiveness = ResponsivenessService(context);
    final isTablet = responsiveness.getScreenType() != Screen.mobile;
    final titleFontSize = isTablet ? 28.0 : 18.0; // Increased tablet font size

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: isAppBarVisible ? 0 : -kToolbarHeight,
      left: 0,
      right: 0,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isAppBarVisible ? 1.0 : 0.0,
        curve: Curves.easeInOutCubic,
        child: AppBar(
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

                  final isSuccess = await initializeService.initialApiCall();

                  if (syncFailed) {
                    await ref
                        .read(userControllerProvider.notifier)
                        .sync(currentUser?.levelId ?? '', currentUser?.subLevel ?? 0);
                  }

                  final progress = ref.read(uIControllerProvider).currentProgress;

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
            ),
          ],
        ),
      ),
    );
  }
}
