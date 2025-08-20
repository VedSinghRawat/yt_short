import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/services/initialize/initialize_service.dart';
import 'package:myapp/controllers/level/level_controller.dart';
import 'package:myapp/views/screens/error_screen.dart';
import 'package:myapp/views/screens/loading_screen.dart';

class InitializeScreen extends ConsumerStatefulWidget {
  const InitializeScreen({super.key});

  @override
  ConsumerState<InitializeScreen> createState() => _InitializeScreenState();
}

class _InitializeScreenState extends ConsumerState<InitializeScreen> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(initializeServiceProvider);

    final levelState = ref.read(levelControllerProvider);

    if (levelState.orderedIds == null) {
      return const LoadingScreen();
    }

    if (_errorMessage != null && levelState.orderedIds!.isEmpty) {
      return Scaffold(
        body: ErrorPage(
          text: _errorMessage!,
          buttonText: "Retry",
          onButtonClick: () async {
            final result = await ref.read(levelControllerProvider.notifier).getOrderedIds();
            result.fold(
              (error) {
                setState(() {
                  _errorMessage = error.message;
                });
              },
              (_) {
                setState(() {
                  _errorMessage = null;
                });
              },
            );
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

    return const LoadingScreen();
  }
}
