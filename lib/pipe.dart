import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';
import 'flappy_game.dart';

/// Üstte ve altta birer renkli tuğla kule; arada geçilecek boşluk ve
/// (bazen) toplanacak bir yıldız.
class TowerPair extends PositionComponent with HasGameReference<FlyGame> {
  static const double towerWidth = 74;

  /// Kule renk paletleri: (gövde, tepe/ağız, derz).
  static const List<List<Color>> palettes = [
    [Color(0xFFFF7B6B), Color(0xFFFFB4A8), Color(0xFFC94F43)], // mercan
    [Color(0xFF9B7BFF), Color(0xFFC9B6FF), Color(0xFF6A4FD1)], // mor
    [Color(0xFF3CC8C0), Color(0xFF9BEBE6), Color(0xFF238F89)], // turkuaz
    [Color(0xFFFFB443), Color(0xFFFFDA9B), Color(0xFFCF8414)], // amber
  ];

  final double gapY;
  final int palette;
  final bool withStar;
  bool scored = false;

  TowerPair({required double x, required this.gapY, required this.palette, required this.withStar})
      : super(position: Vector2(x, 0), size: Vector2(towerWidth, ArcadeGame.virtualSize.y));

  @override
  FutureOr<void> onLoad() {
    final gap = game.difficulty.gap;
    const b = ArcadeGame.bleed;
    final topHeight = gapY - gap / 2;
    final bottomTop = gapY + gap / 2;
    final colors = palettes[palette];
    addAll([
      _Tower(size: Vector2(towerWidth, topHeight + b), position: Vector2(0, -b), capAtBottom: true, colors: colors),
      _Tower(
        size: Vector2(towerWidth, ArcadeGame.virtualSize.y - bottomTop + b),
        position: Vector2(0, bottomTop),
        capAtBottom: false,
        colors: colors,
      ),
    ]);
    if (withStar) add(StarPickup(position: Vector2(towerWidth / 2, gapY)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    position.x += game.currentSpeed * dt;
    if (!scored && position.x + towerWidth < game.flyer.position.x) {
      scored = true;
      game.addPoint();
    }
    if (position.x < game.visibleRect.left - towerWidth - 20) removeFromParent();
  }
}

/// Tek kule: tuğla desenli gövde + boşluğa bakan uçta yuvarlak tepe.
class _Tower extends PositionComponent {
  _Tower({required Vector2 size, required Vector2 position, required this.capAtBottom, required this.colors})
      : super(size: size, position: position) {
    add(RectangleHitbox());
  }

  final bool capAtBottom;
  final List<Color> colors;

  static const double _capHeight = 22;
  static const double _brickH = 14;
  static const double _brickW = 26;

  @override
  void render(Canvas canvas) {
    if (size.y <= 0) return;
    final body = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(body, Paint()..color = colors[0]);

    // Tuğla derzleri (sıra sıra kaydırılmış).
    final mortar = Paint()
      ..color = colors[2].withValues(alpha: 0.55)
      ..strokeWidth = 2;
    var row = 0;
    for (double y = capAtBottom ? size.y % _brickH : 0; y < size.y; y += _brickH, row++) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), mortar);
      final shift = row.isEven ? 0.0 : _brickW / 2;
      for (double x = shift; x < size.x; x += _brickW) {
        canvas.drawLine(Offset(x, y), Offset(x, (y + _brickH).clamp(0, size.y)), mortar);
      }
    }
    // Soldan ışık, sağdan gölge.
    canvas.drawRect(Rect.fromLTWH(0, 0, 8, size.y), Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawRect(Rect.fromLTWH(size.x - 10, 0, 10, size.y), Paint()..color = Colors.black.withValues(alpha: 0.14));

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF2B2140);
    canvas.drawRect(body, edge);

    // Tepe: boşluğa bakan uçta taşkın, yuvarlatılmış blok.
    final capTop = capAtBottom ? size.y - _capHeight : 0.0;
    final cap = RRect.fromRectAndRadius(Rect.fromLTWH(-6, capTop, size.x + 12, _capHeight), const Radius.circular(8));
    canvas.drawRRect(cap, Paint()..color = colors[1]);
    canvas.drawRRect(cap, edge);
    // Tepedeki küçük pencere ışıkları.
    final light = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(size.x * (0.25 + i * 0.25), capTop + _capHeight / 2), 3, light);
    }
  }
}
