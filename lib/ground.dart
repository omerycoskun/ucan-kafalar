import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';
import 'flappy_game.dart';

/// Uç modunun zemini: kayan renkli kaldırım şeridi + çarpışma bandı.
/// Kulelerin önünde çizilir (priority), böylece kule dipleri gizlenir.
class Ground extends PositionComponent with HasGameReference<FlyGame> {
  Ground()
      : super(
          position: Vector2(-ArcadeGame.bleed, ArcadeGame.virtualSize.y - FlyGame.groundHeight),
          size: Vector2(ArcadeGame.virtualSize.x + 2 * ArcadeGame.bleed, FlyGame.groundHeight + ArcadeGame.bleed),
          priority: 8,
        );

  double _offset = 0;
  static const double _tile = 40;

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state == GameState.playing) {
      _offset = (_offset + game.currentSpeed.abs() * dt) % _tile;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = const Color(0xFF6B5BD6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 16), Paint()..color = const Color(0xFFFFC857));
    final stripe = Paint()..color = const Color(0xFFFF8F5A);
    for (double x = -_offset + (ArcadeGame.bleed % _tile); x < size.x; x += _tile) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + 18, 0)
        ..lineTo(x + 8, 16)
        ..lineTo(x - 10, 16)
        ..close();
      canvas.drawPath(path, stripe);
    }
    final dot = Paint()..color = const Color(0x33FFFFFF);
    for (double x = -_offset + (ArcadeGame.bleed % _tile); x < size.x; x += _tile) {
      canvas.drawCircle(Offset(x + 20, 44), 5, dot);
    }
    canvas.drawLine(
      Offset.zero,
      Offset(size.x, 0),
      Paint()
        ..color = const Color(0xFF2B2140)
        ..strokeWidth = 3,
    );
  }
}
