import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kafa.dart';

/// Oyun modları: yatay uçuş ve dikey zıplama.
enum GameMode {
  fly('Uç'),
  jump('Zıpla');

  const GameMode(this.label);
  final String label;
}

/// Uç modunun zorlukları (Zıpla modu skorla kendiliğinden zorlaşır).
enum Difficulty {
  // label, gap (geniş=kolay), speed (yavaş=kolay)
  easy('Kolay', 260, -180),
  medium('Orta', 230, -240),
  hard('Zor', 195, -255),
  // Macera: skor arttıkça kuleler giderek hızlanır (başlangıç değerleri).
  adventure('Macera', 200, -115);

  const Difficulty(this.label, this.gap, this.speed);

  /// Ekranlarda gösterilen Türkçe ad.
  final String label;

  /// Kuleler arası dikey boşluk (piksel). Zor modda daha dar.
  final double gap;

  /// Kule başlangıç yatay hızı (negatif = sola). Macera'da skorla artar.
  final double speed;

  /// Skorla hızlanan macera modu mu?
  bool get isAdventure => this == Difficulty.adventure;

  String get subtitle => isAdventure ? 'Skorla giderek hızlanır' : 'Sabit hız';
}

/// Bir oyun bitince kaydedilen sonuç (UI'da gösterilir).
class RunOutcome {
  const RunOutcome({
    required this.score,
    required this.bestScore,
    required this.starsGained,
    required this.totalStars,
    required this.unlocked,
  });

  final int score;
  final int bestScore;
  final int starsGained;
  final int totalStars;

  /// Bu oyunla YENİ açılan kafalar.
  final List<Kafa> unlocked;
}

/// [totalStars] toplam yıldızla açık olan kafaların sayısı (saf, test edilebilir).
int unlockedCountFor(int totalStars) => kKafalar.where((k) => totalStars >= k.price).length;

/// Tüm kalıcı durum ve ayarların tek merkezden yönetimi.
class GameStore extends ChangeNotifier {
  GameStore._();

  static final GameStore instance = GameStore._();

  static const _kBestFly = 'best_fly';
  static const _kBestJump = 'best_jump';
  static const _kStars = 'total_stars';
  static const _kSelectedKafa = 'selected_kafa';
  static const _kSoundOn = 'sound_on';
  static const _kMusicOn = 'music_on';
  static const _kDifficulty = 'difficulty';

  SharedPreferences? _prefs;

  int _bestFly = 0;
  int _bestJump = 0;
  int _stars = 0;
  int _selectedKafa = 1;
  bool _soundOn = true;
  bool _musicOn = true;
  Difficulty _difficulty = Difficulty.medium;

  int bestScore(GameMode mode) => mode == GameMode.fly ? _bestFly : _bestJump;
  int get totalStars => _stars;
  Kafa get selectedKafa => kafaById(_selectedKafa);
  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  Difficulty get difficulty => _difficulty;

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    _bestFly = p.getInt(_kBestFly) ?? 0;
    _bestJump = p.getInt(_kBestJump) ?? 0;
    _stars = p.getInt(_kStars) ?? 0;
    _selectedKafa = p.getInt(_kSelectedKafa) ?? 1;
    _soundOn = p.getBool(_kSoundOn) ?? true;
    _musicOn = p.getBool(_kMusicOn) ?? true;
    final d = p.getInt(_kDifficulty) ?? Difficulty.medium.index;
    _difficulty = Difficulty.values[d.clamp(0, Difficulty.values.length - 1)];
    if (!isUnlocked(selectedKafa)) _selectedKafa = 1;
    notifyListeners();
  }

  bool isUnlocked(Kafa k) => _stars >= k.price;

  /// Oyun bitince çağrılır: rekoru ve yıldızları kaydeder, yeni açılanları döner.
  Future<RunOutcome> registerRun(GameMode mode, {required int score, required int stars}) async {
    final before = unlockedCountFor(_stars);
    _stars += stars;
    if (mode == GameMode.fly && score > _bestFly) _bestFly = score;
    if (mode == GameMode.jump && score > _bestJump) _bestJump = score;
    final p = _prefs;
    if (p != null) {
      await p.setInt(_kStars, _stars);
      await p.setInt(_kBestFly, _bestFly);
      await p.setInt(_kBestJump, _bestJump);
    }
    final after = unlockedCountFor(_stars);
    notifyListeners();
    return RunOutcome(
      score: score,
      bestScore: bestScore(mode),
      starsGained: stars,
      totalStars: _stars,
      unlocked: kKafalar.where((k) => k.price <= _stars).skip(before).take(after - before).toList(),
    );
  }

  Future<void> selectKafa(Kafa k) async {
    if (!isUnlocked(k)) return;
    _selectedKafa = k.id;
    await _prefs?.setInt(_kSelectedKafa, k.id);
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    await _prefs?.setBool(_kSoundOn, value);
    notifyListeners();
  }

  Future<void> setMusicOn(bool value) async {
    _musicOn = value;
    await _prefs?.setBool(_kMusicOn, value);
    notifyListeners();
  }

  Future<void> setDifficulty(Difficulty value) async {
    _difficulty = value;
    await _prefs?.setInt(_kDifficulty, value.index);
    notifyListeners();
  }

  /// Ayarları varsayılana döndürür (ilerleme — yıldız/rekor — korunur).
  Future<void> resetToDefaults() async {
    await setSoundOn(true);
    await setMusicOn(true);
    await setDifficulty(Difficulty.medium);
  }

  /// Yalnızca testler için: kalıcı depolama olmadan yıldız sayısını ayarlar.
  @visibleForTesting
  void setStarsForTest(int stars) => _stars = stars;
}
