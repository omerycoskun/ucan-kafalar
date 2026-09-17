import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';

/// Uç modunun arka planı (tamamen kodla çizilir): gün batımı gökyüzü, güneş,
/// kayan bulutlar ve iki katmanlı (paralaks) şehir silueti.
class CitySky extends PositionComponent with HasGameReference<ArcadeGame> {
  CitySky() : super(priority: -10);

  final Random _rng = Random(11);
  final List<_Cloud> _clouds = [];
  late final List<double> _farBuildings;
  late final List<double> _nearBuildings;
  double _farX = 0;
  double _nearX = 0;

  static const double _farW = 46;
  static const double _nearW = 64;

  @override
  FutureOr<void> onLoad() {
    size = ArcadeGame.virtualSize.clone();
    for (var i = 0; i < 5; i++) {
      _clouds.add(_Cloud(
        _rng.nextDouble() * size.x,
        40 + _rng.nextDouble() * 260,
        0.6 + _rng.nextDouble() * 0.7,
        8 + _rng.nextDouble() * 14,
      ));
    }
    _farBuildings = List.generate(12, (_) => 120 + _rng.nextDouble() * 150);
    _nearBuildings = List.generate(9, (_) => 70 + _rng.nextDouble() * 110);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final moving = game.state != GameState.gameOver;
    for (final c in _clouds) {
      c.x -= c.speed * dt;
      if (c.x < -ArcadeGame.bleed / 2) {
        c.x = size.x + ArcadeGame.bleed / 2;
        c.y = 40 + _rng.nextDouble() * 260;
      }
    }
    if (moving) {
      _farX = (_farX + 12 * dt) % (_farW * _farBuildings.length);
      _nearX = (_nearX + 30 * dt) % (_nearW * _nearBuildings.length);
    }
  }

  @override
  void render(Canvas canvas) {
    const b = ArcadeGame.bleed;
    final rect = Rect.fromLTWH(-b, -b, size.x + 2 * b, size.y + b);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FA8FF), Color(0xFF9ED8FF), Color(0xFFFFD9A8)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Güneş + hale.
    const sun = Offset(318, 150);
    canvas.drawCircle(sun, 70, Paint()..color = const Color(0x33FFF3B0));
    canvas.drawCircle(sun, 44, Paint()..color = const Color(0xFFFFE27A));

    for (final c in _clouds) {
      _drawCloud(canvas, Offset(c.x, c.y), c.scale);
    }

    final ground = size.y - 78;
    _drawSkyline(canvas, _farBuildings, _farW, _farX, ground, const Color(0xFF8AAFE0));
    _drawSkyline(canvas, _nearBuildings, _nearW, _nearX, ground, const Color(0xFF5C79B8), windows: true);
  }

  void _drawCloud(Canvas canvas, Offset o, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(o, 22 * s, p);
    canvas.drawCircle(o + Offset(24 * s, -10 * s), 28 * s, p);
    canvas.drawCircle(o + Offset(52 * s, 0), 20 * s, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 10 * s, o.dy, 72 * s, 20 * s), Radius.circular(10 * s)),
      p,
    );
  }

  void _drawSkyline(Canvas canvas, List<double> heights, double w, double offset, double ground, Color color,
      {bool windows = false}) {
    final paint = Paint()..color = color;
    final windowPaint = Paint()..color = const Color(0x66FFF3B0);
    final total = w * heights.length;
    const b = ArcadeGame.bleed;
    for (var rep = -2; rep < 4; rep++) {
      for (var i = 0; i < heights.length; i++) {
        final x = i * w - offset + rep * total;
        if (x > size.x + b || x + w < -b) continue;
        final h = heights[i];
        final r = RRect.fromRectAndCorners(Rect.fromLTWH(x + 2, ground - h, w - 4, h),
            topLeft: const Radius.circular(6), topRight: const Radius.circular(6));
        canvas.drawRRect(r, paint);
        if (windows) {
          for (double wy = ground - h + 14; wy < ground - 12; wy += 22) {
            for (double wx = x + 12; wx < x + w - 14; wx += 18) {
              canvas.drawRect(Rect.fromLTWH(wx, wy, 7, 10), windowPaint);
            }
          }
        }
      }
    }
  }
}

class _Cloud {
  _Cloud(this.x, this.y, this.scale, this.speed);
  double x;
  double y;
  final double scale;
  final double speed;
}
