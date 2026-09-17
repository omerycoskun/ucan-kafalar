import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flappybird/arcade.dart';
import 'package:flappybird/flappy_game.dart';
import 'package:flappybird/game_store.dart';
import 'package:flappybird/jump_game.dart';
import 'package:flappybird/kafa.dart';
import 'package:flappybird/ledge.dart';
import 'package:flappybird/pipe.dart';
import 'package:flutter_test/flutter_test.dart';

/// Oyun döngüsünü [seconds] boyunca 60 fps adımlarla ilerletir.
void step(ArcadeGame game, double seconds, {void Function(double t)? each}) {
  var t = 0.0;
  while (t < seconds) {
    game.update(1 / 60);
    each?.call(t);
    t += 1 / 60;
  }
}

void main() {
  setUpAll(() {
    // Test ortamında asset resim çözme beklemede kalabiliyor: karakter
    // sprite'larını önbelleğe yer tutucu görsel olarak önceden koy.
    for (final k in kKafalar) {
      Flame.images.add(k.spritePath, renderKafaImage(k, 64));
    }
  });

  setUp(() async {
    // Testte ses eklentisi yok: sesleri kapat.
    await GameStore.instance.setSoundOn(false);
    await GameStore.instance.setMusicOn(false);
  });

  group('Uç modu', () {
    testWithGame<FlyGame>(
      'dokunulmazsa kafa zemine düşer ve oyun biter',
      () => FlyGame(onGameOver: (_) {}),
      (game) async {
        await game.ready();
        game.startRun();
        game.flyer.flap();
        step(game, 3);
        expect(game.state, GameState.gameOver);
      },
    );

    testWithGame<FlyGame>(
      'düzenli dokunarak havada kalır, kuleler çıkar',
      () => FlyGame(onGameOver: (_) {}),
      (game) async {
        await game.ready();
        game.startRun();
        // Kafayı ekran ortasında tutan basit "otopilot" (kulelere çarpabilir).
        step(game, 2.5, each: (_) {
          if (game.flyer.position.y > 360 && game.flyer.velocity > 0) game.flyer.flap();
        });
        await game.ready();
        expect(game.flyer.isMounted, isTrue);
        expect(game.flyer.position.y, inInclusiveRange(0, ArcadeGame.virtualSize.y));
        expect(game.world.children.whereType<TowerPair>(), isNotEmpty);
      },
    );
  });

  testWithGame<FlyGame>(
    'uzun takılmada (dev dt) kafa zeminin içinden geçip kaybolmaz',
    () => FlyGame(onGameOver: (_) {}),
    (game) async {
      await game.ready();
      game.startRun();
      game.flyer.flap();
      game.updateTree(2.0); // 2 sn donmuş kare
      step(game, 1);
      expect(game.state, GameState.gameOver);
      expect(game.flyer.position.y, lessThan(ArcadeGame.virtualSize.y - FlyGame.groundHeight));
    },
  );

  group('Zıpla modu', () {
    testWithGame<JumpGame>(
      'platformlar üretilir ve kafa zıplayarak yükselir',
      () => JumpGame(onGameOver: (_) {}),
      (game) async {
        await game.ready();
        expect(game.world.children.whereType<Ledge>().length, greaterThan(4));
        final startY = game.jumper.position.y;
        game.onTapDown(createTapDownEvents(game: game));
        step(game, 0.2);
        expect(game.jumper.position.y, lessThan(startY));
        expect(game.state, GameState.playing);
      },
    );
  });

  testWithGame<FlyGame>(
    'yıldız toplanınca sayılır ve yalnızca bir kez',
    () => FlyGame(onGameOver: (_) {}),
    (game) async {
      await game.ready();
      final star = StarPickup(position: Vector2(100, 100));
      await game.world.add(star);
      await game.ready();
      game.collectStar(star);
      game.collectStar(star);
      expect(game.starsThisRun, 1);
    },
  );
}
