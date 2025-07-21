import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/services/initialize/initialize_service.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/views/screens/error_screen.dart';
import 'package:myapp/views/widgets/page_loader.dart';

class InitializeScreen extends ConsumerWidget {
  const InitializeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(initializeServiceProvider);

    final levelState = ref.read(levelControllerProvider);

    if (levelState.orderedIds == null) {
      return const PageLoader();
    }

    if (levelState.error != null && levelState.orderedIds!.isEmpty) {
      return Scaffold(
        body: ErrorPage(
          text: levelState.error.toString(),
          buttonText: "Retry",
          onButtonClick: () async {
            await ref.read(levelControllerProvider.notifier).getOrderedIds();
          },
        ),
      );
    }

    // Trigger navigation when initialized
    initState.whenData((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GoRouter.of(context).go(Routes.home);
      });
    });

    return const PageLoader();
  }
}
