import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zorluk modları. [unlockInterval] her kaç puanda bir sonraki karakterin
/// açıldığını belirler (kolay = daha çok puan gerektirir).
enum Difficulty {
  // label, unlockInterval, pipeGap (geniş=kolay), pipeSpeed (yavaş=kolay)
  easy('Kolay', 30, 260, -180),
  medium('Orta', 18, 230, -240),
  hard('Zor', 10, 195, -255),
  // Macera: skor arttıkça borular giderek hızlanır (başlangıç değerleri).
  adventure('Macera', 15, 200, -115);

  const Difficulty(this.label, this.unlockInterval, this.pipeGap, this.pipeSpeed);

  /// Ekranlarda gösterilen Türkçe ad.
  final String label;

  /// Bir sonraki karakteri açmak için gereken puan aralığı.
  final int unlockInterval;

  /// Borular arası dikey boşluk (piksel). Zor modda daha dar.
  final double pipeGap;

  /// Boru başlangıç yatay hızı (negatif = sola). Macera'da skorla artar.
  final double pipeSpeed;

  /// Skorla hızlanan macera modu mu?
  bool get isAdventure => this == Difficulty.adventure;

  /// Ayarlar/karakter ekranında gösterilen açıklama.
  String get subtitle => isAdventure
      ? 'Skorla hızlanır • her $unlockInterval puanda karakter'
      : 'Her $unlockInterval puanda karakter açılır';
}

/// Toplam karakter sayısı (character_1..character_10 + background_music_1..10).
const int kCharacterCount = 10;

/// Tüm kalıcı durum ve ayarların tek merkezden yönetimi.
/// Değişiklikleri dinleyen ekranlar için [ChangeNotifier].
class GameStore extends ChangeNotifier {
  GameStore._();

  static final GameStore instance = GameStore._();

  static const _kBestScore = 'best_score';
  static const _kUnlockedCount = 'unlocked_count';
  static const _kSelectedChar = 'selected_character';
  static const _kSoundOn = 'sound_on';
  static const _kMusicOn = 'music_on';
  static const _kDifficulty = 'difficulty';

  late SharedPreferences _prefs;
  bool _loaded = false;
  bool get loaded => _loaded;

  int _bestScore = 0;
  int _unlockedCount = 1; // sadece ilk karakter açık başlar
  int _selectedCharacter = 1; // 1-tabanlı
  bool _soundOn = true;
  bool _musicOn = true;
  Difficulty _difficulty = Difficulty.hard;

  int get bestScore => _bestScore;
  int get unlockedCount => _unlockedCount;
  int get selectedCharacter => _selectedCharacter;
  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  Difficulty get difficulty => _difficulty;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _bestScore = _prefs.getInt(_kBestScore) ?? 0;
    _unlockedCount = _prefs.getInt(_kUnlockedCount) ?? 1;
    _selectedCharacter = _prefs.getInt(_kSelectedChar) ?? 1;
    _soundOn = _prefs.getBool(_kSoundOn) ?? true;
    _musicOn = _prefs.getBool(_kMusicOn) ?? true;
    final diffIndex = _prefs.getInt(_kDifficulty) ?? Difficulty.hard.index;
    _difficulty = Difficulty.values[diffIndex.clamp(0, Difficulty.values.length - 1)];
    _loaded = true;
    notifyListeners();
  }

  bool isUnlocked(int character1Based) => character1Based <= _unlockedCount;

  /// Belirli bir karakteri açmak için gereken toplam puan eşiği.
  /// Karakter 1 => 0, karakter 2 => interval, karakter 3 => 2*interval ...
  int unlockThreshold(int character1Based) =>
      (character1Based - 1) * _difficulty.unlockInterval;

  /// Bir oyun bittiğinde çağrılır. En yüksek skoru ve buna bağlı açılan
  /// karakter sayısını günceller. Yeni bir karakter açıldıysa true döner.
  Future<bool> registerRunResult(int score) async {
    var changed = false;
    var newlyUnlocked = false;

    if (score > _bestScore) {
      _bestScore = score;
      await _prefs.setInt(_kBestScore, _bestScore);
      changed = true;
    }

    // Bu skorla kaç karakter açılmış olmalı? (kalıcı, geri kilitlenmez)
    final earned = (1 + (score ~/ _difficulty.unlockInterval))
        .clamp(1, kCharacterCount);
    if (earned > _unlockedCount) {
      _unlockedCount = earned;
      await _prefs.setInt(_kUnlockedCount, _unlockedCount);
      changed = true;
      newlyUnlocked = true;
    }

    if (changed) notifyListeners();
    return newlyUnlocked;
  }

  Future<void> selectCharacter(int character1Based) async {
    if (!isUnlocked(character1Based)) return;
    _selectedCharacter = character1Based;
    await _prefs.setInt(_kSelectedChar, character1Based);
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    _soundOn = value;
    await _prefs.setBool(_kSoundOn, value);
    notifyListeners();
  }

  Future<void> setMusicOn(bool value) async {
    _musicOn = value;
    await _prefs.setBool(_kMusicOn, value);
    notifyListeners();
  }

  Future<void> setDifficulty(Difficulty value) async {
    _difficulty = value;
    await _prefs.setInt(_kDifficulty, value.index);
    notifyListeners();
  }

  /// Yalnızca testler için: kalıcı depolamaya dokunmadan zorluğu ayarlar.
  @visibleForTesting
  void setDifficultyForTest(Difficulty value) => _difficulty = value;

  /// Ayarları ve ilerlemeyi varsayılana döndürür (ayarlar menüsündeki sıfırla).
  Future<void> resetToDefaults() async {
    _soundOn = true;
    _musicOn = true;
    _difficulty = Difficulty.hard;
    _selectedCharacter = 1;
    await _prefs.setBool(_kSoundOn, true);
    await _prefs.setBool(_kMusicOn, true);
    await _prefs.setInt(_kDifficulty, Difficulty.hard.index);
    await _prefs.setInt(_kSelectedChar, 1);
    notifyListeners();
  }
}

/// Karakter -> görsel / müzik eşlemesi. Dosya sonundaki sayı baz alınır:
/// character_N.png <-> background_music_N.mp3.
class CharacterInfo {
  const CharacterInfo(this.id);

  /// 1-tabanlı karakter numarası.
  final int id;

  String get spritePath => 'characters/character_$id.png';
  String get musicPath => 'background_music_$id.mp3';
  String get displayName => 'Karakter $id';
}

const List<CharacterInfo> kCharacters = [
  CharacterInfo(1),
  CharacterInfo(2),
  CharacterInfo(3),
  CharacterInfo(4),
  CharacterInfo(5),
  CharacterInfo(6),
  CharacterInfo(7),
  CharacterInfo(8),
  CharacterInfo(9),
  CharacterInfo(10),
];
