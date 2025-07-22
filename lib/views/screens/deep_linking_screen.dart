import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/controllers/auth/auth_controller.dart';

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
    final currentLang = ref.watch(langControllerProvider); // Watch for language changes

    if (authState.loading) {
      final text = choose(hindi: 'आपका खाता लिंक हो रहा है...', hinglish: 'Linking your account...', lang: currentLang);

      return Scaffold(body: Center(child: Loader(text: text)));
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: authState.error != null ? _buildErrorUI(authState.error!) : _buildSuccessUI(),
        ),
      ),
    );
  }

  Widget _buildErrorUI(String error) {
    final currentLang = ref.read(langControllerProvider);
    final headingText = choose(hindi: 'सिंक फेल हो गया', hinglish: 'Sync failed', lang: currentLang);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('❌', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(headingText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _syncCyId,
          child: const Text('Retry'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildSuccessUI() {
    final currentLang = ref.read(langControllerProvider);

    final headingText = choose(hindi: 'सिंक सफल हो गया', hinglish: 'Sync safal hogya', lang: currentLang);
    final buttonText = choose(hindi: 'आगे बढ़ें ', hinglish: 'Aage badhe', lang: currentLang);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(headingText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.goNamed(Routes.home);
            }
          },
          child: Text(buttonText),
        ),
      ],
    );
  }
}
