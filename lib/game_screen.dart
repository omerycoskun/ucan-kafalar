import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'ad_banner.dart';
import 'ad_service.dart';
import 'flappy_game.dart';
import 'ui_common.dart';

/// Oyunu barındıran ekran. GameWidget + duraklat butonu + game-over / pause overlay.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final FlappyGame _game;
  RunResult? _lastResult;
  bool _paused = false;
  bool _usedContinue = false; // oyun başına 1 "reklamla devam" hakkı
  bool _watchingAd = false;

  @override
  void initState() {
    super.initState();
    _game = FlappyGame(onGameOver: _handleGameOver);
  }

  void _handleGameOver(RunResult result) {
    setState(() => _lastResult = result);
    _game.overlays.add('gameOver');
    // Arada bir geçiş reklamı (her 3 oyunda bir; mobil dışında no-op).
    AdService.instance.notifyGameOverAndMaybeShow();
  }

  void _restart() {
    _game.overlays.remove('gameOver');
    _game.restart();
    setState(() {
      _lastResult = null;
      _usedContinue = false;
    });
  }

  /// "İzle & Devam Et": ödüllü reklam izlenirse kaldığı yerden devam.
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
        _lastResult = null;
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
    // Duraklatma sırasında motor donmuş olabilir; menüye dönmeden önce çöz.
    _game.resumeEngine();
    goBackOrMenu(context);
  }

  bool get _showPauseButton => _lastResult == null && !_paused;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sky,
      body: Column(
        children: [
          Expanded(
            // RepaintBoundary: oyunun çizimini alttaki banner (platform view)
            // compositing'inden yalıtır → boruların titremesi/takılması azalır.
            child: RepaintBoundary(
              child: Stack(
              children: [
                GameWidget<FlappyGame>(
                  game: _game,
                  overlayBuilderMap: {
                    'gameOver': (context, game) => _GameOverOverlay(
                          result: _lastResult,
                          onRestart: _restart,
                          onMenu: _exitToMenu,
                          // Reklamla devam yalnızca reklam hazırsa ve bu oyunda
                          // henüz kullanılmadıysa gösterilir (web'de asla).
                          onWatchContinue: (!_usedContinue &&
                                  AdService.instance.canShowRewarded)
                              ? _watchAndContinue
                              : null,
                          watchingAd: _watchingAd,
                        ),
                    'pause': (context, game) => _PauseOverlay(
                          onResume: _resume,
                          onMenu: _exitToMenu,
                        ),
                  },
                ),
                // Duraklat butonu (game-over / duraklatma dışında görünür).
                if (_showPauseButton)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _RoundIconButton(
                          icon: Icons.pause,
                          onTap: _pause,
                        ),
                      ),
                    ),
                  ),
              ],
              ),
            ),
          ),
          // Alt banner reklam (mobilde; web/masaüstünde no-op).
          const AdBanner(),
        ],
      ),
    );
  }
}

/// Sağ üstteki yuvarlak duraklat butonu.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Duraklatma menüsü: Devam Et + Menüye Dön.
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onMenu});

  final VoidCallback onResume;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Duraklatıldı',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 22),
            MenuButton(label: 'Devam Et', icon: Icons.play_arrow, onPressed: onResume),
            const SizedBox(height: 12),
            MenuButton(
              label: 'Menüye Dön',
              icon: Icons.home,
              color: AppColors.orange,
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.result,
    required this.onRestart,
    required this.onMenu,
    required this.onWatchContinue,
    required this.watchingAd,
  });

  final RunResult? result;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  /// null ise "reklamla devam" gösterilmez (reklam hazır değil / kullanıldı / web).
  final VoidCallback? onWatchContinue;
  final bool watchingAd;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Oyun Bitti',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 16),
            _statRow('Skor', '${r?.score ?? 0}'),
            const SizedBox(height: 6),
            _statRow('En İyi', '${r?.bestScore ?? 0}'),
            if (r?.newCharacterUnlocked ?? false) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_open, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Yeni karakter açıldı!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            if (onWatchContinue != null) ...[
              MenuButton(
                label: watchingAd ? 'Yükleniyor...' : 'İzle & Devam Et',
                icon: Icons.ondemand_video,
                color: AppColors.grass,
                onPressed: watchingAd ? () {} : onWatchContinue!,
              ),
              const SizedBox(height: 12),
            ],
            MenuButton(
              label: 'Tekrar Oyna',
              icon: Icons.refresh,
              color: onWatchContinue != null ? AppColors.sky : AppColors.grass,
              onPressed: onRestart,
            ),
            const SizedBox(height: 12),
            MenuButton(
              label: 'Menü',
              icon: Icons.home,
              color: AppColors.orange,
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 20, color: AppColors.dark)),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
      ],
    );
  }
}
