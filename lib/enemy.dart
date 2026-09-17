// _dir private alan olduğu için initializing formal (this._dir) kullanılamaz.
// ignore_for_file: prefer_initializing_formals
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';
import 'jump_game.dart';

/// Değince oyunu bitiren düşman (kod ile çizilir: kızgın kırmızı yaratık).
/// Yatay gidip gelir; dünya kaydıkça JumpGame onu da aşağı iter.
class Enemy extends PositionComponent with HasGameReference<JumpGame> {
  static const double diameter = 46;
  static const double _speed = 58;

  double _dir;

  Enemy({required Vector2 position, double dir = 1})
      : _dir = dir,
        super(
          position: position,
          size: Vector2.all(diameter),
          anchor: Anchor.center,
        ) {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    position.x += _dir * _speed * dt;
    final r = diameter / 2;
    if (position.x < r) {
      position.x = r;
      _dir = 1;
    } else if (position.x > ArcadeGame.virtualSize.x - r) {
      position.x = ArcadeGame.virtualSize.x - r;
      _dir = -1;
    }
  }

  @override
  void render(Canvas canvas) {
    final r = diameter / 2;
    final c = Offset(r, r);

    // Gövde: kırmızı radial gradyan.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFB00020)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66000000),
    );

    // Gözler (beyaz + siyah bebek).
    final eyeW = Paint()..color = Colors.white;
    final pupil = Paint()..color = Colors.black;
    for (final sx in [-1.0, 1.0]) {
      final e = c + Offset(sx * r * 0.34, -r * 0.10);
      canvas.drawCircle(e, r * 0.24, eyeW);
      canvas.drawCircle(e, r * 0.11, pupil);
    }

    // Kızgın kaşlar + asık ağız.
    final line = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(c + Offset(-r * 0.58, -r * 0.5),
        c + Offset(-r * 0.12, -r * 0.28), line);
    canvas.drawLine(c + Offset(r * 0.58, -r * 0.5),
        c + Offset(r * 0.12, -r * 0.28), line);
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, r * 0.62), radius: r * 0.32),
      pi,
      pi,
      false,
      line,
    );
  }
}
