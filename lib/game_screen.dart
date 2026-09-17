import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'ad_banner.dart';
import 'ad_service.dart';
import 'arcade.dart';
import 'flappy_game.dart';
import 'game_store.dart';
import 'jump_game.dart';
import 'kafa.dart';
import 'ui_common.dart';

/// Oyunu barındıran ekran (iki mod için ortak): GameWidget + duraklat butonu +
/// oyun sonu / duraklatma overlay'leri + alt banner. Zıpla modunda eğim ve
/// parmakla yön verme de buradan beslenir.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final ArcadeGame _game;
  RunOutcome? _outcome;
  bool _paused = false;
  bool _usedContinue = false; // oyun başına 1 "reklamla devam" hakkı
  bool _watchingAd = false;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  JumpGame? get _jump {
    final g = _game;
    return g is JumpGame ? g : null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode == GameMode.fly) {
      _game = FlyGame(onGameOver: _handleGameOver);
    } else {
      _game = JumpGame(onGameOver: _handleGameOver);
      // Eğimle yatay kontrol (mobil); veri gelmezse parmak kontrolü çalışır.
      try {
        _accelSub = accelerometerEventStream().listen((e) => _jump?.setTilt(e.x));
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _handleGameOver(RunOutcome outcome) {
    if (!mounted) return;
    setState(() => _outcome = outcome);
    _game.overlays.add('gameOver');
    AdService.instance.notifyGameOverAndMaybeShow();
  }

  void _restart() {
    _game.overlays.remove('gameOver');
    _game.restart();
    setState(() {
      _outcome = null;
      _usedContinue = false;
    });
  }

  Future<void> _watchAndContinue() async {
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    final rewarded = await AdService.instance.showRewardedContinue();
    if (!mounted) return;
    setState(() => _watchingAd = false);
    if (rewarded) {
      _game.overlays.remove('gameOver');
      _game.continueRun();
      setState(() {
        _outcome = null;
        _usedContinue = true;
      });
    }
  }

  void _pause() {
    if (!_game.isPlaying) return;
    _game.pauseGame();
    setState(() => _paused = true);
  }

  void _resume() {
    _game.resumeGame();
    setState(() => _paused = false);
  }

  void _exitToMenu() {
    _game.resumeEngine();
    goBackOrMenu(context);
  }

  bool get _showPauseButton => _outcome == null && !_paused;

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      children: [
        GameWidget<ArcadeGame>(
          game: _game,
          overlayBuilderMap: {
            'gameOver': (context, game) => _GameOverOverlay(
                  outcome: _outcome,
                  onRestart: _restart,
                  onMenu: _exitToMenu,
                  onWatchContinue:
                      (!_usedContinue && AdService.instance.canShowRewarded) ? _watchAndContinue : null,
                  watchingAd: _watchingAd,
                ),
            'pause': (context, game) => _PauseOverlay(onResume: _resume, onMenu: _exitToMenu),
          },
        ),
        if (_showPauseButton)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _RoundIconButton(icon: Icons.pause_rounded, onTap: _pause),
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          Expanded(
            // RepaintBoundary: oyun çizimini alttaki banner'dan yalıtır.
            child: RepaintBoundary(
              child: _jump == null
                  ? stack
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final vw = ArcadeGame.virtualSize.x;
                        final vh = ArcadeGame.virtualSize.y;
                        // Ekran pikselini oyunun sanal x'ine çevir.
                        double toWorldX(double localX) {
                          final scale = min(w / vw, h / vh);
                          final offX = (w - vw * scale) / 2;
                          return ((localX - offX) / scale).clamp(0.0, vw);
                        }

                        return Listener(
                          onPointerDown: (e) => _jump!.aimAt(toWorldX(e.localPosition.dx)),
                          onPointerMove: (e) => _jump!.aimAt(toWorldX(e.localPosition.dx)),
                          onPointerUp: (_) => _jump!.releaseAim(),
                          onPointerCancel: (_) => _jump!.releaseAim(),
                          child: stack,
                        );
                      },
                    ),
            ),
          ),
          const AdBanner(),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.55),
      shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, color: Colors.white, size: 28)),
      ),
    );
  }
}

/// Overlay paneli: krem kart + kalın çerçeve.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.ink, width: 4),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onMenu});

  final VoidCallback onResume;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _Panel(children: [
      const Text('Duraklatıldı', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
      const SizedBox(height: 20),
      MenuButton(label: 'Devam Et', icon: Icons.play_arrow_rounded, color: AppColors.teal, onPressed: onResume),
      const SizedBox(height: 12),
      MenuButton(label: 'Menüye Dön', icon: Icons.home_rounded, color: AppColors.violet, onPressed: onMenu),
    ]);
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.outcome,
    required this.onRestart,
    required this.onMenu,
    required this.onWatchContinue,
    required this.watchingAd,
  });

  final RunOutcome? outcome;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  /// null ise "reklamla devam" gösterilmez (reklam hazır değil / kullanıldı / web).
  final VoidCallback? onWatchContinue;
  final bool watchingAd;

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    return _Panel(children: [
      const Text('Oyun Bitti', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink)),
      const SizedBox(height: 14),
      _statRow('Skor', '${o?.score ?? 0}'),
      const SizedBox(height: 4),
      _statRow('Rekor', '${o?.bestScore ?? 0}'),
      const SizedBox(height: 4),
      _statRow('Yıldız', '+${o?.starsGained ?? 0}  (toplam ${o?.totalStars ?? 0})'),
      for (final k in o?.unlocked ?? const <Kafa>[]) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KafaView(k, size: 40),
              const SizedBox(width: 8),
              Text('${k.name} açıldı!',
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      if (onWatchContinue != null) ...[
        MenuButton(
          label: watchingAd ? 'Yükleniyor...' : 'İzle & Devam Et',
          icon: Icons.ondemand_video_rounded,
          color: AppColors.coral,
          onPressed: watchingAd ? () {} : onWatchContinue!,
        ),
        const SizedBox(height: 12),
      ],
      MenuButton(label: 'Tekrar Oyna', icon: Icons.refresh_rounded, color: AppColors.teal, onPressed: onRestart),
      const SizedBox(height: 12),
      MenuButton(label: 'Menü', icon: Icons.home_rounded, color: AppColors.violet, onPressed: onMenu),
    ]);
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, color: AppColors.ink, fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
        ),
      ],
    );
  }
}
