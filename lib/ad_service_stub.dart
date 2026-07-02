/// Reklam desteklemeyen platformlar (web/masaüstü) için boş servis.
/// Tüm çağrılar güvenli şekilde hiçbir şey yapmaz.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  Future<void> initialize() async {}

  /// Oyun bitti; gerekiyorsa geçiş reklamı gösterir (burada no-op).
  Future<void> notifyGameOverAndMaybeShow() async {}

  /// Ödüllü "devam" reklamı hazır mı? Web'de asla.
  bool get canShowRewarded => false;

  /// Ödüllü reklam gösterir; ödül kazanılırsa true. Web'de her zaman false.
  Future<bool> showRewardedContinue() async => false;
}
