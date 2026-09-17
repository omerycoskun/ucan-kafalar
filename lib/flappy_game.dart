import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'arcade.dart';
import 'background.dart';
import 'bird.dart';
import 'game_store.dart';
import 'ground.dart';
import 'pipe.dart';

/// "Uç" modu: dokunarak yüksel, renkli tuğla kulelerin arasından geç,
/// aralıklarda duran yıldızları topla.
class FlyGame extends ArcadeGame {
  FlyGame({required super.onGameOver});

  static const double gravity = 1400;
  static const double flapVelocity = -400;
  static const double groundHeight = 78;
  // Ardışık kuleler arasındaki sabit yatay mesafe (hızdan bağımsız).
  static const double towerSpacing = 300;
  // Macera modu: her puanda hıza eklenen ivme ve tavan hız.
  static const double adventureSpeedPerPoint = 5;
  static const double adventureMaxSpeed = -330;
  // Kule aralığına yıldız konma olasılığı.
  static const double starChance = 0.65;

  @override
  GameMode get mode => GameMode.fly;

  @override
  String get readyMessage => 'Uçmak için dokun';

  Difficulty get difficulty => store.difficulty;

  /// O anki kule hızı. Macera modunda skorla hızlanır (bir tavana kadar).
  double get currentSpeed {
    if (!difficulty.isAdventure) return difficulty.speed;
    final s = difficulty.speed - score * adventureSpeedPerPoint;
    return s < adventureMaxSpeed ? adventureMaxSpeed : s;
  }

  double get _spawnInterval => towerSpacing / currentSpeed.abs();

  late final Flyer flyer;
  double _spawnTimer = 0;
  final Random _random = Random();

  Vector2 get _startPosition => Vector2(ArcadeGame.virtualSize.x * 0.3, ArcadeGame.virtualSize.y * 0.42);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    flyer = Flyer(kafa: kafa, position: _startPosition);
    world.addAll([CitySky(), Ground(), flyer]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnTower();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    switch (state) {
      case GameState.ready:
        startRun();
        flyer.flap();
      case GameState.playing:
        flyer.flap();
        playSfx('jump.wav', 0.35);
      case GameState.gameOver:
        break; // Yeniden başlatma overlay üzerinden.
    }
  }

  void addPoint() => setScore(score + 1);

  @override
  void resetWorld() {
    flyer.reset(_startPosition);
    world.children.whereType<TowerPair>().toList().forEach((p) => p.removeFromParent());
    _spawnTimer = 0;
  }

  @override
  void prepareContinue() {
    flyer.reset(_startPosition);
    world.children
        .whereType<TowerPair>()
        .where((p) => p.position.x < ArcadeGame.virtualSize.x * 0.95)
        .toList()
        .forEach((p) => p.removeFromParent());
    _spawnTimer = 0;
  }

  void _spawnTower() {
    const margin = 110.0;
    final playable = ArcadeGame.virtualSize.y - groundHeight - margin * 2;
    final gapY = margin + _random.nextDouble() * playable;
    world.add(TowerPair(
      x: max(ArcadeGame.virtualSize.x, visibleRect.right) + 30,
      gapY: gapY,
      palette: _random.nextInt(TowerPair.palettes.length),
      withStar: _random.nextDouble() < starChance,
    ));
  }
}
