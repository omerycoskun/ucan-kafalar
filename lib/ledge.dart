import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';
import 'jump_game.dart';

/// Zıplanacak bulut-platform (kodla çizilir). [moving] ise yatay gidip gelir.
class Ledge extends PositionComponent with HasGameReference<JumpGame> {
  static const double ledgeW = 78;
  static const double ledgeH = 20;
  static const double halfWidth = ledgeW / 2;
  static const double _speed = 75;

  final bool moving;
  double _dir = 1;

  Ledge({required Vector2 position, this.moving = false})
      : super(position: position, size: Vector2(ledgeW, ledgeH), anchor: Anchor.center) {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!moving || game.state != GameState.playing) return;
    position.x += _dir * _speed * dt;
    if (position.x < halfWidth) {
      position.x = halfWidth;
      _dir = 1;
    } else if (position.x > ArcadeGame.virtualSize.x - halfWidth) {
      position.x = ArcadeGame.virtualSize.x - halfWidth;
      _dir = -1;
    }
  }

  @override
  void render(Canvas canvas) {
    final base = moving ? const Color(0xFFFFB86B) : const Color(0xFF8EF0C8);
    final dark = moving ? const Color(0xFFD9772A) : const Color(0xFF2FA97A);
    final rect = Rect.fromLTWH(0, 4, ledgeW, ledgeH - 4);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.drawRRect(rrect.shift(const Offset(0, 3)), Paint()..color = dark);
    canvas.drawRRect(rrect, Paint()..color = base);
    // Üstte kabarık bulut tümsekleri.
    final bump = Paint()..color = base;
    for (final x in [16.0, 39.0, 62.0]) {
      canvas.drawCircle(Offset(x, 7), 9, bump);
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x552B2140),
    );
  }
}
