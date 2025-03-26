import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:myapp/core/services/interstitial_ad_service.dart';
import 'package:myapp/core/widgets/loader.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await MobileAds.instance.initialize();

  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAd = ref.watch(interstitialAdNotifierProvider.select((state) => state.showAd));

    return MaterialApp(
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
      home: Scaffold(
        body: showAd
            ? const InterstitialAdWidget()
            : Stack(
                children: [
                  // Your main content here
                  const Center(child: Text('Main App Content')),

                  // Button to show ad (positioned wherever you want)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () async {
                        ref.read(interstitialAdNotifierProvider.notifier).setShowAd(true);
                        await FirebaseAnalytics.instance.logEvent(
                          name: 'button_click',
                          parameters: {
                            'button_name': 'login_button',
                            'click_time': DateTime.now().toString(),
                          },
                        );
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
  const InterstitialAdWidget({
    super.key,
  });

  @override
  ConsumerState<InterstitialAdWidget> createState() => _InterstitialAdWidgetState();
}

class _InterstitialAdWidgetState extends ConsumerState<InterstitialAdWidget> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(interstitialAdNotifierProvider.notifier);
      await notifier.watchAd();
    });
  }

  Future<void> _handleAd() async {}

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(interstitialAdNotifierProvider);

    //a full screen gray background
    return Container(
      color: Colors.grey.withValues(alpha: 0.9),
      child: Center(
        child: adState.isLoading
            ? const Loader()
            : adState.error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertically center the content
                    children: [
                      // Error message
                      Text(
                        adState.error ?? 'Something went wrong',
                        style: const TextStyle(fontSize: 18), // Optional: improve readability
                      ),
                      const SizedBox(height: 20), // Add spacing between text and button
                      // Retry button
                      FloatingActionButton(
                        onPressed: _handleAd,
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  )
                : null,
      ),
    );
  }
}
