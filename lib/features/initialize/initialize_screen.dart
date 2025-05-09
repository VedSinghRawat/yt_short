import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/sublevel/level_controller.dart';
import 'package:myapp/features/sublevel/widget/error_page.dart';

class InitializeScreen extends ConsumerWidget {
  const InitializeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(initializeServiceProvider);

    final oIds = ref.read(levelControllerProvider);

    if (oIds.isLoading) {
      return const Loader();
    }

    if (oIds.hasError) {
      return Scaffold(
        body: ErrorPage(
          text: oIds.error.toString(),
          buttonText: "Retry",
          onRefresh: () async {
            await ref.read(levelControllerProvider.notifier).getOrderedIds();
          },
        ),
      );
    }

    // Trigger navigation when initialized
    initState.whenData((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        developer.log('navigating to home');
        GoRouter.of(context).go(Routes.home);
      });
    });

    // Show a loader while anything (loading/data/error) happens
    return const Scaffold(body: Loader());
  }
}
