import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/router/router.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/views/widgets/loader.dart';
import 'package:myapp/views/widgets/lang_text.dart';
import 'package:myapp/controllers/auth/auth_controller.dart';

class DeepLinkingScreen extends ConsumerStatefulWidget {
  const DeepLinkingScreen({super.key});

  @override
  ConsumerState<DeepLinkingScreen> createState() => _DeepLinkingScreenState();
}

class _DeepLinkingScreenState extends ConsumerState<DeepLinkingScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _syncCyId();
  }

  Future<void> _syncCyId() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final error = await ref.read(authControllerProvider.notifier).syncCyId();
      if (error != null) {
        developer.log('Error syncing cyId: ${error.message}', error: error.trace);
        setState(() {
          _errorMessage = error.message;
        });
      }
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
          child: _errorMessage != null ? _buildErrorUI(_errorMessage!) : _buildSuccessUI(),
        ),
      ),
    );
  }

  Widget _buildErrorUI(String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LangText.bodyText(text: '❌', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const LangText.heading(hindi: 'सिंक फेल हो गया', hinglish: 'Sync failed', style: TextStyle(fontSize: 24)),
        const SizedBox(height: 12),
        LangText.bodyText(
          text: error,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
          onPressed: _syncCyId,
          child: const LangText.bodyText(text: 'Retry'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
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
          child: const LangText.bodyText(text: 'Cancel'),
        ),
      ],
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LangText.bodyText(text: '🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const LangText.heading(hindi: 'सिंक सफल हो गया', hinglish: 'Sync safal hogya', style: TextStyle(fontSize: 24)),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.goNamed(Routes.home);
            }
          },
          child: const LangText.body(hindi: 'आगे बढ़ें', hinglish: 'Aage badhe'),
        ),
      ],
    );
  }
}
