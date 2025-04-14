import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:myapp/features/auth/auth_controller.dart';

class DeepLinkingScreen extends ConsumerStatefulWidget {
  const DeepLinkingScreen({super.key});

  @override
  ConsumerState<DeepLinkingScreen> createState() => _DeepLinkingScreenState();
}

class _DeepLinkingScreenState extends ConsumerState<DeepLinkingScreen> {
  @override
  void initState() {
    super.initState();
    _syncCyId();
  }

  Future<void> _syncCyId() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).syncCyId();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState.loading) {
      return const Scaffold(
        body: Center(child: Loader(text: 'Linking your account...')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              authState.error != null
                  ? _buildErrorUI(context, authState.error!)
                  : _buildSuccessUI(context),
        ),
      ),
    );
  }

  Widget _buildErrorUI(BuildContext context, String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('❌', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text(
          "Sync Failed",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _syncCyId,
          child: const Text('Retry'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.grey[800],
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.goNamed(Routes.home);
            }
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildSuccessUI(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text(
          "You're all set!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.goNamed(Routes.home);
            }
          },
          child: const Text('Continue'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.red[100],
            foregroundColor: Colors.red[800],
          ),
          onPressed: SystemNavigator.pop,
          child: const Text('Close App'),
        ),
      ],
    );
  }
}
