import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'arcade.dart';
import 'flappy_game.dart';

/// Uç modunda oyuncunun kafası.
class Flyer extends KafaSprite with CollisionCallbacks, HasGameReference<FlyGame> {
  Flyer({required super.kafa, required Vector2 position}) : super(size: 104, position: position, priority: 5);

  double velocity = 0;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    // Görsel omuzlarla birlikte: çarpışma alanı eski boyutta (r≈25) ve kafaya yakın.
    add(CircleHitbox(radius: 25, position: size / 2 + Vector2(0, size.y * 0.02), anchor: Anchor.center));
  }

  void flap() => velocity = FlyGame.flapVelocity;

  void reset(Vector2 startPosition) {
    position = startPosition.clone();
    velocity = 0;
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    velocity += FlyGame.gravity * dt;
    position.y += velocity * dt;
    angle = (velocity / 1100).clamp(-0.4, 0.8);
    if (position.y - size.y / 2 < 0) {
      position.y = size.y / 2;
      velocity = 0;
    }
    // Zemin kontrolü çarpışmadan bağımsız: hiçbir durumda zeminin altına düşmesin.
    final groundTop = ArcadeGame.virtualSize.y - FlyGame.groundHeight;
    if (position.y + size.y * 0.3 >= groundTop) {
      position.y = groundTop - size.y * 0.3;
      game.endGame();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state != GameState.playing) return;
    if (other is StarPickup) {
      game.collectStar(other);
      return;
    }
    game.endGame();
  }
}
