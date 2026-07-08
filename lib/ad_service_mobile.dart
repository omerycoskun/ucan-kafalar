import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Android/iOS için AdMob reklam servisi.
///
/// Reklam birimi kimlikleri: iOS ve Android için ayrı gerçek AdMob kimlikleri
/// (aynı AdMob hesabı pub-1630797078588417; her platform ayrı uygulama).
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _gameOverCount = 0;
  bool _initialized = false;

  static const int _interstitialEvery = 2; // her 2 oyun sonunda bir

  String get _interstitialUnit => Platform.isAndroid
      ? 'ca-app-pub-1630797078588417/8187820623' // Android gerçek (Geçiş)
      : 'ca-app-pub-1630797078588417/5980158365'; // iOS gerçek (Geçiş)

  String get _rewardedUnit => Platform.isAndroid
      ? 'ca-app-pub-1630797078588417/6781158624' // Android gerçek (Ödüllü)
      : 'ca-app-pub-1630797078588417/9726584846'; // iOS gerçek (Ödüllü)

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Oyun bitince çağrılır; her [_interstitialEvery] oyunda bir geçiş reklamı
  /// gösterir (hazırsa). Reklam yoksa sessizce geçer.
  Future<void> notifyGameOverAndMaybeShow() async {
    _gameOverCount++;
    if (_gameOverCount % _interstitialEvery != 0) return;
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }

  bool get canShowRewarded => _rewarded != null;

  /// Ödüllü reklam gösterir; kullanıcı ödülü kazanırsa (izlerse) true döner.
  Future<bool> showRewardedContinue() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (ad, reward) => earned = true);
    return completer.future;
  }
}
