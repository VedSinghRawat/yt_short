import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/loader.dart';


class InterstitialAdWrapper extends ConsumerStatefulWidget {
  const InterstitialAdWrapper({
    super.key,
  });

  @override
  ConsumerState<InterstitialAdWrapper> createState() => _InterstitialAdWrapperState();
}

  class _InterstitialAdWrapperState extends ConsumerState<InterstitialAdWrapper> {
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
