import 'dart:async';

import 'package:flame/components.dart';

import 'flappy_game.dart';

/// Arka plan resmini sanal ekrana "cover" mantığıyla (yüksekliği doldurur,
/// yanları taşarsa ortalanır) yerleştirir. Statik; kaydırma yapmaz.
class Background extends SpriteComponent with HasGameReference<FlappyGame> {
  Background() : super(priority: -10);

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('game_background.jpg');
    final ratio = sprite!.srcSize.x / sprite!.srcSize.y;
    final h = FlappyGame.virtualSize.y;
    final w = h * ratio;
    size = Vector2(w, h);
    anchor = Anchor.topCenter;
    position = Vector2(FlappyGame.virtualSize.x / 2, 0);
  }
}
