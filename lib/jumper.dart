import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'arcade.dart';
import 'enemy.dart';
import 'jump_game.dart';
import 'ledge.dart';

/// Zıpla modunda oyuncunun kafası.
class Jumper extends KafaSprite
    with CollisionCallbacks, HasGameReference<JumpGame> {
  Jumper({required super.kafa, required Vector2 position})
    : super(size: 82, position: position, priority: 5);

  final Vector2 velocity = Vector2.zero();

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(
      RectangleHitbox.relative(
        Vector2(0.62, 0.72),
        parentSize: size,
        position: size / 2 + Vector2(0, 4),
        anchor: Anchor.center,
      ),
    );
  }

  void reset(Vector2 startPosition) {
    position = startPosition.clone();
    velocity.setZero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    velocity.y += JumpGame.gravity * dt;
    position.y += velocity.y * dt;
    // Zıplarken hafif ezilip uzama (canlılık).
    scale = Vector2(
      1 + (velocity.y / 9000).clamp(-0.08, 0.08),
      1 - (velocity.y / 9000).clamp(-0.08, 0.08),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state != GameState.playing) return;
    if (other is StarPickup) {
      game.collectStar(other);
    } else if (other is Enemy) {
      game.endGame();
    } else if (other is Ledge &&
        velocity.y > 0 &&
        position.y < other.position.y) {
      game.bounce();
    }
  }
}
