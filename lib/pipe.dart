import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'flappy_game.dart';

class PipePair extends PositionComponent with HasGameReference<FlappyGame> {
  static const double pipeWidth = 70;

  final double gapY;
  bool scored = false;

  PipePair({required double x, required this.gapY})
      : super(
          position: Vector2(x, 0),
          size: Vector2(pipeWidth, FlappyGame.virtualSize.y),
        );

  @override
  FutureOr<void> onLoad() {
    final gap = game.difficulty.pipeGap;
    final topHeight = gapY - gap / 2;
    final bottomTop = gapY + gap / 2;
    // Alt boru ekranın en altına kadar iner; zeminle arasında boşluk kalmaz.
    final bottomHeight = FlappyGame.virtualSize.y - bottomTop;

    addAll([
      _PipeSegment(
        size: Vector2(pipeWidth, topHeight),
        position: Vector2.zero(),
        capAtBottom: true,
      ),
      _PipeSegment(
        size: Vector2(pipeWidth, bottomHeight),
        position: Vector2(0, bottomTop),
        capAtBottom: false,
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    position.x += game.currentPipeSpeed * dt;

    if (!scored && position.x + pipeWidth < game.bird.position.x) {
      scored = true;
      game.addScore();
    }

    if (position.x < -pipeWidth) {
      removeFromParent();
    }
  }
}

/// Tek bir boru parçası; kod ile çizilir (gövde gradyanı + ağız/cap + kenarlık).
/// [capAtBottom] true ise ağız aşağıda (üstten sarkan boru), false ise yukarıda.
class _PipeSegment extends PositionComponent with CollisionCallbacks {
  final bool capAtBottom;

  static const double _capHeight = 26;
  static const double _capOverhang = 5;

  _PipeSegment({
    required Vector2 size,
    required Vector2 position,
    required this.capAtBottom,
  }) : super(size: size, position: position, anchor: Anchor.topLeft) {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (size.y <= 0) return;

    // Gövde: soldan sağa açık->koyu->açik yeşil gradyan (silindir hissi).
    final bodyRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF5B8A1E),
          Color(0xFF8FD44A),
          Color(0xFF74BF2E),
          Color(0xFF4E7A1A),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(bodyRect);
    canvas.drawRect(bodyRect, bodyPaint);

    // Gövde kenarlığı.
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF3C5E12);
    canvas.drawRect(bodyRect, edgePaint);

    // Ağız (cap): boşluğa bakan uçta, gövdeden biraz taşkın.
    final capTop = capAtBottom ? size.y - _capHeight : 0.0;
    final capRect = Rect.fromLTWH(
      -_capOverhang,
      capTop,
      size.x + _capOverhang * 2,
      _capHeight,
    );
    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0xFF4E7A1A),
          Color(0xFF9BDE52),
          Color(0xFF6FB528),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(capRect);
    canvas.drawRect(capRect, capPaint);
    canvas.drawRect(capRect, edgePaint);
  }
}
