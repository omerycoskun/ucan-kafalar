import 'package:flappybird/game_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unlock threshold scales with difficulty interval', () {
    final store = GameStore.instance;

    // Eşik = (karakter-1) * zorluğun unlockInterval'ı (değerden bağımsız test).
    store.setDifficultyForTest(Difficulty.hard);
    expect(store.unlockThreshold(1), 0);
    expect(store.unlockThreshold(2), Difficulty.hard.unlockInterval);
    expect(store.unlockThreshold(3), 2 * Difficulty.hard.unlockInterval);

    store.setDifficultyForTest(Difficulty.easy);
    expect(store.unlockThreshold(2), Difficulty.easy.unlockInterval);

    store.setDifficultyForTest(Difficulty.adventure);
    expect(store.unlockThreshold(2), Difficulty.adventure.unlockInterval);
    expect(store.unlockThreshold(3), 2 * Difficulty.adventure.unlockInterval);
    expect(Difficulty.adventure.isAdventure, isTrue);
    expect(Difficulty.hard.isAdventure, isFalse);
  });

  test('character maps to matching music by trailing number', () {
    const info = CharacterInfo(7);
    expect(info.spritePath, 'characters/character_7.png');
    expect(info.musicPath, 'background_music_7.mp3');
  });
}
