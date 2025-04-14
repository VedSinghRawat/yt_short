import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/services/initialize_service.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/sublevel/ordered_ids_notifier.dart';
import 'package:myapp/features/sublevel/widget/last_level.dart';

class InitializeScreen extends ConsumerWidget {
  const InitializeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(initializeServiceProvider);

    final oIds = ref.read(orderedIdsNotifierProvider);

    if (oIds.isLoading) {
      return const Loader();
    }

    if (oIds.hasError) {
      return Scaffold(
        body: ErrorPage(
          text: oIds.error.toString(),
          buttonText: "Retry",
          onRefresh: () async {
            await ref.read(orderedIdsNotifierProvider.notifier).getOrderedIds();
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
