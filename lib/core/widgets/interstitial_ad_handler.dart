import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/interstitial_ad_controller.dart';
import '../widgets/loader.dart';

class InterstitialAdHandler extends ConsumerStatefulWidget {
  const InterstitialAdHandler({super.key, this.onAdFinished});

  final void Function()? onAdFinished;

  @override
  ConsumerState<InterstitialAdHandler> createState() => _InterstitialAdHandlerState();
}

class _InterstitialAdHandlerState extends ConsumerState<InterstitialAdHandler> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleAd();
    });
  }

  Future<void> _handleAd() async {
    final notifier = ref.read(interstitialAdNotifierProvider.notifier);
    await notifier.watchAd(widget.onAdFinished);
  }

  @override
  Widget build(BuildContext context) {
    final adState = ref.watch(interstitialAdNotifierProvider);

    //a full screen gray background
    return Container(
      color: Colors.grey.withValues(alpha: 0.9),
      child: Center(
        child:
            adState.isLoading
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
                    FloatingActionButton(onPressed: _handleAd, child: const Icon(Icons.refresh)),
                  ],
                )
                : null,
      ),
    );
  }
}
