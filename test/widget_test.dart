import 'package:flappybird/game_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unlock threshold scales with difficulty interval', () {
    final store = GameStore.instance;

    // Hard: 35'lik aralık. Karakter 2 -> 35, karakter 3 -> 70.
    store.setDifficultyForTest(Difficulty.hard);
    expect(store.unlockThreshold(1), 0);
    expect(store.unlockThreshold(2), 35);
    expect(store.unlockThreshold(3), 70);

    // Easy: 105'lik aralık.
    store.setDifficultyForTest(Difficulty.easy);
    expect(store.unlockThreshold(2), 105);

    // Adventure (Macera): 50'lik aralık, skorla hızlanır.
    store.setDifficultyForTest(Difficulty.adventure);
    expect(store.unlockThreshold(2), 50);
    expect(store.unlockThreshold(3), 100);
    expect(Difficulty.adventure.isAdventure, isTrue);
    expect(Difficulty.hard.isAdventure, isFalse);
  });

  test('character maps to matching music by trailing number', () {
    const info = CharacterInfo(7);
    expect(info.spritePath, 'characters/character_7.png');
    expect(info.musicPath, 'background_music_7.mp3');
  });
}
