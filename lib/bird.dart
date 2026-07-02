import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'flappy_game.dart';

class Bird extends SpriteComponent
    with CollisionCallbacks, HasGameReference<FlappyGame> {
  // Karakterler hedef yükseklikte gösterilir (belirgin ve okunaklı boyut).
  // Sadece çok yatık fotoğraflar (ör. character_1) ekranı kaplamasın diye
  // genişlik [maxWidth] ile sınırlanır; o durumda yükseklik orantılı küçülür.
  static const double targetHeight = 90;
  static const double maxWidth = 124;

  double velocity = 0;
  final int characterId;

  Bird({required this.characterId, required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite('characters/character_$characterId.png');
    final src = sprite!.srcSize;
    final ratio = src.x / src.y;
    var h = targetHeight;
    var w = h * ratio;
    if (w > maxWidth) {
      w = maxWidth;
      h = w / ratio;
    }
    size = Vector2(w, h);

    // Fotoğrafın merkezine oturan, biraz küçültülmüş adil bir çarpışma kutusu.
    add(
      RectangleHitbox.relative(
        Vector2(0.62, 0.72),
        parentSize: size,
        position: size / 2,
        anchor: Anchor.center,
      ),
    );
  }

  void flap() {
    velocity = FlappyGame.flapVelocity;
  }

  void reset(Vector2 startPosition) {
    position = startPosition;
    velocity = 0;
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    velocity += FlappyGame.gravity * dt;
    position.y += velocity * dt;
    angle = (velocity / 900).clamp(-0.5, 1.1);

    if (position.y - size.y / 2 < 0) {
      position.y = size.y / 2;
      velocity = 0;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state == GameState.playing) {
      game.endGame();
    }
  }
}
