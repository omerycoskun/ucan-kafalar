import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'background.dart';
import 'bird.dart';
import 'game_store.dart';
import 'ground.dart';
import 'pipe.dart';

enum GameState { ready, playing, gameOver }

/// Oyun bitince UI'ın sonucu gösterebilmesi için taşınan özet.
class RunResult {
  RunResult({
    required this.score,
    required this.bestScore,
    required this.newCharacterUnlocked,
  });

  final int score;
  final int bestScore;
  final bool newCharacterUnlocked;
}

class FlappyGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  static const double gravity = 1400;
  static const double flapVelocity = -400;
  // Arka plandaki görsel zemin (çim/kum) çizgisiyle hizalı çarpışma bandı;
  // kuş görünen zemine değince yanar (havada değil).
  static const double groundHeight = 78;
  // Ardışık borular arasındaki sabit yatay mesafe. Boru hızından bağımsız
  // tutulur; böylece yavaş modda borular hem yavaş hem seyrek olur (=kolay).
  static const double pipeSpacing = 300;
  // Macera modu: her puanda hıza eklenen ivme ve ulaşılabilecek en yüksek hız.
  static const double adventureSpeedPerPoint = 5;
  static const double adventureMaxSpeed = -330;
  static final Vector2 virtualSize = Vector2(400, 711);

  /// O anki boru hızı. Macera modunda skorla hızlanır (bir tavana kadar),
  /// diğer modlarda zorluğun sabit hızıdır.
  double get currentPipeSpeed {
    if (!difficulty.isAdventure) return difficulty.pipeSpeed;
    final s = difficulty.pipeSpeed - score * adventureSpeedPerPoint;
    return s < adventureMaxSpeed ? adventureMaxSpeed : s;
  }

  /// Boru üretim aralığı = mesafe / hız. Hız arttıkça borular sıklaşır ama
  /// aralarındaki yatay mesafe sabit kalır.
  double get _spawnInterval => pipeSpacing / currentPipeSpeed.abs();

  /// Oyun bittiğinde çağrılır; UI game-over ekranını açar.
  final void Function(RunResult result) onGameOver;

  FlappyGame({required this.onGameOver});

  final GameStore store = GameStore.instance;
  Difficulty get difficulty => store.difficulty;

  GameState state = GameState.ready;
  int score = 0;

  late final Bird bird;
  late final TextComponent scoreText;
  late final TextComponent messageText;

  double _spawnTimer = 0;
  final Random _random = Random();
  bool _musicStarted = false;

  Vector2 get _birdStartPosition =>
      Vector2(virtualSize.x * 0.3, virtualSize.y * 0.42);

  @override
  Color backgroundColor() => const Color(0xFF70C5CE);

  @override
  FutureOr<void> onLoad() async {
    camera.viewfinder.visibleGameSize = virtualSize;
    camera.viewfinder.position = virtualSize / 2;
    camera.viewfinder.anchor = Anchor.center;

    bird = Bird(
      characterId: store.selectedCharacter,
      position: _birdStartPosition,
    );

    world.addAll([
      Background(),
      Ground(),
      bird,
    ]);

    scoreText = TextComponent(
      text: '0',
      position: Vector2(virtualSize.x / 2, 64),
      anchor: Anchor.center,
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFFFFF),
          shadows: [Shadow(color: Color(0xAA000000), offset: Offset(2, 2), blurRadius: 2)],
        ),
      ),
    );

    messageText = TextComponent(
      text: 'Başlamak için dokun',
      position: Vector2(virtualSize.x / 2, virtualSize.y * 0.62),
      anchor: Anchor.center,
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFFFFF),
          shadows: [Shadow(color: Color(0xAA000000), offset: Offset(1, 1), blurRadius: 2)],
        ),
      ),
    );

    world.addAll([scoreText, messageText]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state != GameState.playing) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnPipe();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    switch (state) {
      case GameState.ready:
        _startGame();
        break;
      case GameState.playing:
        bird.flap();
        break;
      case GameState.gameOver:
        break; // Yeniden başlatma UI (overlay) üzerinden yapılır.
    }
  }

  void _startGame() {
    state = GameState.playing;
    messageText.text = '';
    bird.flap();
    _startMusic();
  }

  // --- Ses yardımcıları: her çağrı güvenli; ses hatası oyunu ASLA çökertmez.
  void _startMusic() {
    if (_musicStarted || !store.musicOn) return;
    _musicStarted = true;
    final info = CharacterInfo(store.selectedCharacter);
    try {
      FlameAudio.bgm.play(info.musicPath, volume: 0.6);
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

  void _playHit() {
    if (!store.soundOn) return;
    try {
      FlameAudio.play('hit.wav', volume: 0.9);
    } catch (_) {}
  }

  void addScore() {
    score++;
    scoreText.text = '$score';
  }

  Future<void> endGame() async {
    if (state == GameState.gameOver) return;
    state = GameState.gameOver;

    _playHit();
    _stopMusic();

    // Skor/kilit kaydı ses veya depolamadan bağımsız olarak UI'ı tetiklemeli.
    var newUnlock = false;
    try {
      newUnlock = await store.registerRunResult(score);
    } catch (_) {}

    onGameOver(RunResult(
      score: score,
      bestScore: store.bestScore,
      newCharacterUnlocked: newUnlock,
    ));
  }

  /// Overlay'deki "Tekrar Oyna" butonundan çağrılır.
  void restart() {
    _stopMusic();
    score = 0;
    scoreText.text = '0';
    bird.reset(_birdStartPosition);
    world.children.whereType<PipePair>().toList().forEach(
          (p) => p.removeFromParent(),
        );
    _spawnTimer = 0;
    state = GameState.ready;
    messageText.text = 'Başlamak için dokun';
  }

  /// Ödüllü reklam izlendikten sonra kaldığı yerden devam (skor korunur).
  /// Kuş güvenli konuma alınır ve önündeki yakın borular temizlenir.
  void continueRun() {
    bird.reset(_birdStartPosition);
    world.children.whereType<PipePair>().where((p) {
      // Kuşa çarpabilecek kadar yakın/önündeki boruları temizle.
      return p.position.x < virtualSize.x * 0.95;
    }).toList().forEach((p) => p.removeFromParent());
    _spawnTimer = 0;
    state = GameState.playing;
    _startMusic();
  }

  // --- Duraklatma ---
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

  bool get isPlaying => state == GameState.playing;

  void _spawnPipe() {
    const margin = 110.0;
    final playableHeight = virtualSize.y - groundHeight - margin * 2;
    final gapY = margin + _random.nextDouble() * playableHeight;
    world.add(PipePair(x: virtualSize.x + 40, gapY: gapY));
  }

  @override
  void onRemove() {
    _stopMusic();
    super.onRemove();
  }
}
