import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'arcade.dart';
import 'enemy.dart';
import 'game_store.dart';
import 'jumper.dart';
import 'ledge.dart';
import 'space_sky.dart';

/// "Zıpla" modu: platformdan platforma otomatik zıplayarak uzaya tırman.
/// Telefonu eğerek (ya da parmakla) yön verilir.
class JumpGame extends ArcadeGame {
  JumpGame({required super.onGameOver});

  static const double gravity = 1300;
  static const double jumpVelocity = -760;
  static const double _tiltFactor = 110; // eğim → yatay hız
  static const double _tiltResponse = 22;
  static const double _maxHorizontalSpeed = 520;

  /// Oyuncu ekranda bu yükseklikte tutulur; üstüne çıkınca dünya aşağı kayar.
  static const double scrollLine = 300;

  @override
  GameMode get mode => GameMode.jump;

  @override
  String get readyMessage => 'Zıplamak için dokun';

  double _climb = 0; // toplam tırmanış (skor kaynağı)
  double _scoreClock = 0;

  late final Jumper jumper;
  final Random _random = Random();
  double? _aimX; // parmakla hedeflenen yatay konum (eğim yoksa)
  double _tiltX = 0;
  bool _tiltActive = false;

  static double get _w => ArcadeGame.virtualSize.x;
  static double get _h => ArcadeGame.virtualSize.y;

  /// Platform aralığı: skorla artar. Max zıplama ~220px.
  double get _platformGap => (92 + score / 4).clamp(92, 158).toDouble();
  double get _movingChance => (0.10 + score / 500).clamp(0.10, 0.5).toDouble();
  double get _enemyChance => (0.02 + score / 1200).clamp(0.02, 0.16).toDouble();
  static const double _starChance = 0.22;

  Vector2 get _startPosition => Vector2(_w / 2, _h - 120);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    messageText.position = Vector2(_w / 2, _h * 0.5);
    world.add(SpaceSky());
    jumper = Jumper(kafa: kafa, position: _startPosition);
    world.add(jumper);
    _spawnInitialPlatforms();
  }

  void _spawnInitialPlatforms() {
    world.add(Ledge(position: Vector2(_w / 2, _h - 60)));
    double y = _h - 60;
    final spawnTop = min(0.0, visibleRect.top) - _platformGap;
    while (y > spawnTop) {
      y -= _platformGap;
      _spawnLedgeAt(y);
    }
  }

  void _spawnLedgeAt(double y) {
    final x =
        Ledge.halfWidth + _random.nextDouble() * (_w - Ledge.halfWidth * 2);
    final moving = _random.nextDouble() < _movingChance;
    world.add(Ledge(position: Vector2(x, y), moving: moving));

    if (!moving && _random.nextDouble() < _starChance) {
      world.add(StarPickup(position: Vector2(x, y - 46)));
    }
    if (score > 20 && _random.nextDouble() < _enemyChance) {
      final ex =
          Enemy.diameter / 2 + _random.nextDouble() * (_w - Enemy.diameter);
      world.add(
        Enemy(
          position: Vector2(ex, y - _platformGap * 0.5),
          dir: _random.nextBool() ? 1 : -1,
        ),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (state == GameState.ready) {
      startRun();
      jumper.velocity.y = jumpVelocity;
    }
  }

  void aimAt(double worldX) => _aimX = worldX;
  void releaseAim() => _aimX = null;

  void setTilt(double accelX) {
    _tiltX = accelX;
    _tiltActive = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;

    // Yatay: eğim öncelikli; yoksa parmak.
    if (_tiltActive) {
      // Çok küçük sensör gürültüsünü yok say; gerçek eğimde daha hızlı tepki ver.
      final tilt = _tiltX.abs() < 0.12 ? 0.0 : _tiltX;
      final targetVx = (-tilt * _tiltFactor).clamp(
        -_maxHorizontalSpeed,
        _maxHorizontalSpeed,
      );
      jumper.velocity.x +=
          (targetVx - jumper.velocity.x) * (dt * _tiltResponse).clamp(0, 1);
      jumper.position.x += jumper.velocity.x * dt;
      if (jumper.position.x < 0) jumper.position.x += _w;
      if (jumper.position.x > _w) jumper.position.x -= _w;
    } else if (_aimX != null) {
      final half = jumper.size.x / 2;
      final tx = _aimX!.clamp(half, _w - half);
      jumper.position.x += (tx - jumper.position.x) * (dt * 12).clamp(0, 1);
    }

    // Dünya kaydırma: oyuncu scrollLine'ın üstüne çıkınca her şeyi aşağı it.
    if (jumper.position.y < scrollLine) {
      final delta = scrollLine - jumper.position.y;
      jumper.position.y = scrollLine;
      _climb += delta;

      double topY = double.infinity;
      for (final c in world.children) {
        if (c is Ledge) {
          c.position.y += delta;
          if (c.position.y > max(_h, visibleRect.bottom) + 40) {
            c.removeFromParent();
          } else if (c.position.y < topY) {
            topY = c.position.y;
          }
        } else if (c is Enemy || (c is StarPickup && !c.decorative)) {
          final p = c as PositionComponent;
          p.position.y += delta;
          if (p.position.y > max(_h, visibleRect.bottom) + 40) {
            p.removeFromParent();
          }
        }
      }
      if (topY == double.infinity) topY = 0;
      final spawnTop = min(0.0, visibleRect.top) - _platformGap;
      while (topY > spawnTop) {
        topY -= _platformGap;
        _spawnLedgeAt(topY);
      }
      score = (_climb / 10).floor();
    }

    // Skor yazısını saniyede ~10 kez güncelle.
    _scoreClock += dt;
    if (_scoreClock >= 0.1) {
      _scoreClock = 0;
      if (scoreText.text != '$score') scoreText.text = '$score';
    }

    if (jumper.position.y - jumper.size.y / 2 > max(_h, visibleRect.bottom)) {
      endGame();
    }
  }

  /// Jumper bir platforma üstten değince çağrılır.
  void bounce() {
    jumper.velocity.y = jumpVelocity;
    playSfx('jump.wav', 0.5);
  }

  @override
  void resetWorld() {
    _climb = 0;
    _scoreClock = 0;
    for (final c in world.children.toList()) {
      if (c is Ledge || c is Enemy || (c is StarPickup && !c.decorative)) {
        c.removeFromParent();
      }
    }
    jumper.reset(_startPosition);
    _spawnInitialPlatforms();
    _aimX = null;
  }

  @override
  void prepareContinue() {
    jumper.reset(Vector2(_w / 2, scrollLine));
    world.children.whereType<Enemy>().toList().forEach(
      (e) => e.removeFromParent(),
    );
    world.add(Ledge(position: Vector2(_w / 2, scrollLine + 70)));
    _aimX = null;
    jumper.velocity.y = jumpVelocity;
  }
}
