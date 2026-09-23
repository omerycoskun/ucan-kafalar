import 'package:flappybird/game_store.dart';
import 'package:flappybird/kafa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kafalar yıldız fiyatına göre sıralı ve ilk kafa ücretsiz', () {
    expect(kKafalar.first.price, 0);
    for (var i = 1; i < kKafalar.length; i++) {
      expect(kKafalar[i].price, greaterThan(kKafalar[i - 1].price));
    }
    expect(kKafalar.map((k) => k.id).toSet().length, kKafalar.length);
  });

  test('toplam yıldızla açılan kafa sayısı', () {
    expect(unlockedCountFor(0), 1);
    expect(unlockedCountFor(kKafalar[1].price - 1), 1);
    expect(unlockedCountFor(kKafalar[1].price), 2);
    expect(unlockedCountFor(100000), kKafalar.length);
  });

  test('registerRun yıldızları biriktirir ve yeni açılanları döner', () async {
    final store = GameStore.instance;
    store.setStarsForTest(kKafalar[1].price - 2);
    final outcome = await store.registerRun(GameMode.jump, score: 42, stars: 5);
    expect(outcome.totalStars, kKafalar[1].price + 3);
    expect(outcome.unlocked.map((k) => k.id), [kKafalar[1].id]);
    expect(outcome.bestScore, 42);
    expect(store.bestScore(GameMode.fly), 0);
  });

  test('ödüllü reklam yıldız ekler ve yeni açılan karakteri döner', () async {
    final store = GameStore.instance;
    store.setStarsForTest(kKafalar[1].price - GameStore.rewardedStarAmount);
    final unlocked = await store.addRewardedStars();
    expect(store.totalStars, kKafalar[1].price);
    expect(unlocked.map((k) => k.id), [kKafalar[1].id]);
  });

  test('karakter görseli ve müziği numarasıyla eşleşir', () {
    expect(kafaById(7).musicPath, 'background_music_7.mp3');
    expect(kafaById(7).imageAsset, 'assets/images/characters/character_7.png');
    expect(kafaById(999).id, kKafalar.first.id);
  });
}
