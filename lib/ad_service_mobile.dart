import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/widgets.dart';
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
    // iOS: reklamlardan önce ATT (takip izni) penceresini göster (App Store 2.1).
    await ensureTrackingPermission();
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
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
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

  Future<bool> showRewardedContinue() => showRewarded();
}

/// iOS ATT (takip izni) penceresini GÜVENİLİR biçimde göster.
///
/// Apple 2.1 reddi: "AppTrackingTransparency kullanılıyor ama izin penceresini
/// bulamadık" (iPadOS 26.x). Sebep: izin penceresi ancak uygulama ön planda ve
/// AKTİF durumdayken açılabilir. Flutter'ın ilk karesi çizildiğinde uygulama
/// hâlâ `inactive` olabiliyor (özellikle iPad'de); o anda yapılan istek sessizce
/// düşüyor ve pencere bir daha hiç görünmüyor. Bu yüzden: önce `resumed`
/// durumunu bekle, kısa bir nefes al, sonra iste ve gerekirse tekrar dene.
Future<void> ensureTrackingPermission() async {
  if (!Platform.isIOS) return;
  var status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status != TrackingStatus.notDetermined) return;

  // Uygulama aktif olana kadar bekle (en fazla ~4 sn).
  for (var i = 0; i < 40; i++) {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  await Future<void>.delayed(const Duration(milliseconds: 500));

  // İlk istek yine de düşerse birkaç kez dene.
  for (var i = 0; i < 3; i++) {
    status = await AppTrackingTransparency.requestTrackingAuthorization();
    if (status != TrackingStatus.notDetermined) return;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
