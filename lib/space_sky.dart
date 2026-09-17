import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';

/// Zıpla modunun arka planı: alttan mavi → üstte uzay moru, yıldızlar ve
/// uzakta bir gezegen (kodla çizilir).
class SpaceSky extends PositionComponent {
  SpaceSky() : super(priority: -10);

  final List<Offset> _stars = [];
  final Random _rng = Random(7);
  double _t = 0;

  @override
  FutureOr<void> onLoad() {
    size = ArcadeGame.virtualSize.clone();
    const b = ArcadeGame.bleed;
    for (var i = 0; i < 200; i++) {
      _stars.add(Offset(-b + _rng.nextDouble() * (size.x + 2 * b), -b + _rng.nextDouble() * (size.y * 0.8 + b)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    const b = ArcadeGame.bleed;
    final rect = Rect.fromLTWH(-b, -b, size.x + 2 * b, size.y + 2 * b);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF6FA8FF), Color(0xFF4A3B8F), Color(0xFF160E33)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    for (var i = 0; i < _stars.length; i++) {
      final twinkle = 0.45 + 0.4 * sin(_t * 2 + i);
      canvas.drawCircle(_stars[i], 1.7, Paint()..color = Colors.white.withValues(alpha: twinkle));
    }
    // Halkalı gezegen.
    const p = Offset(90, 150);
    canvas.drawCircle(p, 34, Paint()..color = const Color(0xFFFF9FD2));
    canvas.drawCircle(p + const Offset(-10, -10), 12, Paint()..color = const Color(0x55FFFFFF));
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 110, height: 26),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xCCFFE27A),
    );
    canvas.restore();
  }
}
