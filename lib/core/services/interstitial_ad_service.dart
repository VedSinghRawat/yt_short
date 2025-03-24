import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'interstitial_ad_service.g.dart';

class InterstitialAdState {
  final InterstitialAd? interstitialAd;
  final bool isLoading;
  final String? error;
  final bool showAd;

  const InterstitialAdState({
    this.interstitialAd,
    this.isLoading = false,
    this.error,
    this.showAd = false,
  });

  // Helper method to copy the state with new values
  InterstitialAdState copyWith({
    InterstitialAd? interstitialAd,
    bool? isLoading,
    String? error,
    bool? showAd,
  }) {
    return InterstitialAdState(
      interstitialAd: interstitialAd ?? this.interstitialAd,
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

  Future<void> loadAd() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['DD4DCA6D1F5BA6CD1311D99E96A28ABF'],
        ),
      );

      state = state.copyWith(isLoading: true, error: null);

      await InterstitialAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            state = state.copyWith(
              interstitialAd: ad,
              isLoading: false,
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> watchAd() async {
    if (state.interstitialAd == null) {
      await loadAd();
    }
    await state.interstitialAd?.show();
    await state.interstitialAd?.dispose();
    state = state.copyWith(interstitialAd: null, showAd: false);
    await loadAd();
  }

  void setShowAd(bool showAd) {
    state = state.copyWith(showAd: showAd);
  }
}
