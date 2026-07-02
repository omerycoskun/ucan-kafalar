import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'flappy_game.dart';

/// Görünmez zemin çarpışma bandı. Zeminin görseli arka plan resminde
/// (game_background.jpg) yer aldığı için burada sadece çarpışma kutusu var.
class Ground extends PositionComponent {
  Ground()
      : super(
          position: Vector2(0, FlappyGame.virtualSize.y - FlappyGame.groundHeight),
          size: Vector2(FlappyGame.virtualSize.x, FlappyGame.groundHeight),
        );

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox());
  }
}
