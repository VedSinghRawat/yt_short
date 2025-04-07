import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'interstitial_ad_service.g.dart';

class InterstitialAdState {
  final bool isLoading;
  final String? error;
  final bool showAd;

  const InterstitialAdState({
    this.isLoading = false,
    this.error,
    this.showAd = false,
  });

  // Helper method to copy the state with new values
  InterstitialAdState copyWith({
    bool? isLoading,
    String? error,
    bool? showAd,
  }) {
    return InterstitialAdState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      showAd: showAd ?? this.showAd,
    );
  }
}

@riverpod
class InterstitialAdNotifier extends _$InterstitialAdNotifier {
  @override
  InterstitialAdState build() => const InterstitialAdState();

  Future<void> watchAd() async {
    if (state.isLoading) {
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);
      await Future.delayed(const Duration(seconds: 3));

      await InterstitialAd.load(
        adUnitId: dotenv.env["INTERSTITIAL_AD_UNIT_ID"] ?? 'ca-app-pub-3940256099942544/1033173712',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) async {
            state = state.copyWith(
              isLoading: false,
              error: null,
            );

            await ad.show();
            await ad.dispose();

            state = state.copyWith(
              showAd: false,
            );
          },
          onAdFailedToLoad: (error) {
            state = state.copyWith(
              isLoading: false,
              error: error.toString(),
            );
          },
        ),
      );
    } catch (e) {
      developer.log('loadAd: error $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void setShowAd(bool showAd) {
    state = state.copyWith(showAd: showAd);
  }
}
