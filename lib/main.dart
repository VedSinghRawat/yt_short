import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:myapp/core/services/interstitial_ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());

  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAd = ref.watch(interstitialAdNotifierProvider.select((state) => state.showAd));

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Ad overlay
            if (showAd) const InterstitialAdWidget(),

            // Your main content here
            const Center(child: Text('Main App Content here')),

            // Button to show ad (positioned wherever you want)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  ref.read(interstitialAdNotifierProvider.notifier).setShowAd(true);
                },
                child: const Icon(Icons.ad_units),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InterstitialAdWidget extends ConsumerStatefulWidget {
  const InterstitialAdWidget({super.key});

  @override
  ConsumerState<InterstitialAdWidget> createState() => _InterstitialAdWidgetState();
}

class _InterstitialAdWidgetState extends ConsumerState<InterstitialAdWidget> {
  @override
  void initState() {
    super.initState();
    // Load and show ad when widget is first rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAd();
    });
  }

  Future<void> _handleAd() async {
    final notifier = ref.read(interstitialAdNotifierProvider.notifier);
    try {
      await notifier.watchAd();
    } catch (e) {
      // Error will be automatically handled by the state
      debugPrint('Failed to show ad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(interstitialAdNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator
        if (adState.interstitialAd == null && adState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          )
        else if (adState.interstitialAd == null && adState.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  'Ad Error: ${adState.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: _handleAd,
                  child: const Text('Retry Ad'),
                )
              ],
            ),
          ),
      ],
    );
  }
}
