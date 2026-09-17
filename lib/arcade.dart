import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'game_store.dart';
import 'kafa.dart';

enum GameState { ready, playing, gameOver }

/// Uç ve Zıpla modlarının ortak tabanı: durum, skor, yıldız, ses, duraklatma.
abstract class ArcadeGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  ArcadeGame({required this.onGameOver});

  /// Oyun bitince UI'ı tetikler.
  final void Function(RunOutcome outcome) onGameOver;

  static final Vector2 virtualSize = Vector2(400, 711);

  /// Ekran oranı 400x711'den farklıysa (uzun telefon, iPad) kenarlarda boşluk
  /// kalmasın diye arka planlar ve engeller bu kadar taşarak çizilir.
  static const double bleed = 700;

  /// Kameranın o an gösterdiği dünya alanı (letterbox dahil).
  Rect get visibleRect => camera.visibleWorldRect;

  GameMode get mode;

  final GameStore store = GameStore.instance;
  Kafa get kafa => store.selectedKafa;

  GameState state = GameState.ready;
  int score = 0;
  int starsThisRun = 0;
  bool _musicStarted = false;

  late final TextComponent scoreText;
  late final TextComponent starText;
  late final TextComponent messageText;

  bool get isPlaying => state == GameState.playing;

  /// Başlangıç mesajı ("Başlamak için dokun" vb.).
  String get readyMessage;

  /// Mod'a özel sıfırlama (dünya temizliği, oyuncuyu başa alma).
  void resetWorld();

  /// Mod'a özel "reklamla devam" hazırlığı (oyuncuyu güvenli konuma al).
  void prepareContinue();

  @override
  FutureOr<void> onLoad() async {
    camera.viewfinder.visibleGameSize = virtualSize;
    camera.viewfinder.position = virtualSize / 2;
    camera.viewfinder.anchor = Anchor.center;

    const shadow = [Shadow(color: Color(0xAA000000), offset: Offset(2, 2), blurRadius: 2)];
    scoreText = TextComponent(
      text: '0',
      position: Vector2(virtualSize.x / 2, 60),
      anchor: Anchor.center,
      priority: 20,
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Roboto', fontSize: 50, fontWeight: FontWeight.w900, color: Colors.white, shadows: shadow),
      ),
    );
    world.add(StarPickup(position: Vector2(26, 24), decorative: true)..priority = 20);
    starText = TextComponent(
      text: '0',
      position: Vector2(46, 24),
      anchor: Anchor.centerLeft,
      priority: 20,
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFD84D), shadows: shadow),
      ),
    );
    messageText = TextComponent(
      text: readyMessage,
      position: Vector2(virtualSize.x / 2, virtualSize.y * 0.62),
      anchor: Anchor.center,
      priority: 20,
      textRenderer: TextPaint(
        style: const TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadow),
      ),
    );
    world.addAll([scoreText, starText, messageText]);
  }

  /// Uzun bir takılmadan (arka plana alma, yavaş kare) sonra gelen dev `dt`
  /// oyuncuyu tek adımda engellerin/zeminin içinden geçirmesin diye sınırlanır.
  @override
  void updateTree(double dt) => super.updateTree(min(dt, 1 / 30));

  void setScore(int value) {
    if (value == score) return;
    score = value;
    scoreText.text = '$value';
  }

  void collectStar(StarPickup star) {
    if (star.collected) return;
    star.collect();
    starsThisRun++;
    starText.text = '$starsThisRun';
    playSfx('star.wav', 0.7);
  }

  void startRun() {
    state = GameState.playing;
    messageText.text = '';
    _startMusic();
  }

  Future<void> endGame() async {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;
    playSfx('hit.wav', 0.9);
    _stopMusic();
    RunOutcome outcome;
    try {
      outcome = await store.registerRun(mode, score: score, stars: starsThisRun);
    } catch (_) {
      outcome = RunOutcome(score: score, bestScore: score, starsGained: starsThisRun, totalStars: 0, unlocked: const []);
    }
    onGameOver(outcome);
  }

  /// "Tekrar Oyna".
  void restart() {
    _stopMusic();
    score = 0;
    starsThisRun = 0;
    scoreText.text = '0';
    starText.text = '0';
    resetWorld();
    state = GameState.ready;
    messageText.text = readyMessage;
  }

  /// Ödüllü reklamdan sonra kaldığı yerden devam (skor ve yıldızlar korunur).
  void continueRun() {
    prepareContinue();
    state = GameState.playing;
    _startMusic();
  }

  void pauseGame() {
    if (state != GameState.playing) return;
    overlays.add('pause');
    try {
      FlameAudio.bgm.pause();
    } catch (_) {}
    pauseEngine();
  }

  void resumeGame() {
    overlays.remove('pause');
    resumeEngine();
    if (_musicStarted) {
      try {
        FlameAudio.bgm.resume();
      } catch (_) {}
    }
  }

  // --- Ses: her çağrı güvenli; ses hatası oyunu ASLA çökertmez.
  void playSfx(String file, double volume) {
    if (!store.soundOn) return;
    try {
      FlameAudio.play(file, volume: volume);
    } catch (_) {}
  }

  void _startMusic() {
    if (_musicStarted || !store.musicOn) return;
    _musicStarted = true;
    try {
      FlameAudio.bgm.play(kafa.musicPath, volume: 0.6);
    } catch (_) {
      _musicStarted = false;
    }
  }

  void _stopMusic() {
    if (!_musicStarted) return;
    _musicStarted = false;
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  @override
  void onRemove() {
    _stopMusic();
    super.onRemove();
  }
}

/// Oyuncunun kafası: bir kez rasterlanıp sprite olarak çizilir.
class KafaSprite extends SpriteComponent {
  KafaSprite({required this.kafa, required double size, super.position, super.priority})
      : super(size: Vector2.all(size), anchor: Anchor.center);

  final Kafa kafa;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(renderKafaImage(kafa, 160));
  }
}

/// Toplanabilir yıldız (iki modda da). Hafifçe süzülür ve parlar.
class StarPickup extends PositionComponent {
  /// [decorative] ise HUD ikonu: çarpışmaz, toplanmaz.
  StarPickup({required Vector2 position, this.decorative = false})
      : super(position: position, size: Vector2.all(34), anchor: Anchor.center) {
    if (!decorative) add(CircleHitbox(radius: 17));
  }

  final bool decorative;

  bool collected = false;
  double _t = Random().nextDouble() * 6;
  double _pop = 0;

  void collect() {
    collected = true;
    children.whereType<CircleHitbox>().forEach((h) => h.removeFromParent());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (collected) {
      _pop += dt * 4;
      if (_pop >= 1) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2 + sin(_t * 4) * 3);
    final scale = collected ? 1 + _pop * 0.8 : 1.0;
    final alpha = collected ? (1 - _pop).clamp(0.0, 1.0) : 1.0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale);
    canvas.rotate(sin(_t * 2) * 0.15);
    canvas.drawCircle(Offset.zero, 17, Paint()..color = Color.fromRGBO(255, 230, 120, 0.35 * alpha));
    final p = starPath(Offset.zero, 15, 7);
    canvas.drawPath(p, Paint()..color = Color.fromRGBO(255, 205, 40, alpha));
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromRGBO(140, 80, 0, alpha),
    );
    canvas.restore();
  }
}
