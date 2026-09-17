import 'package:flutter/material.dart';

import 'character_screen.dart';
import 'game_screen.dart';
import 'game_store.dart';
import 'kafa.dart';
import 'settings_screen.dart';
import 'ui_common.dart';

/// Ana menü: seçili kafa, iki oyun modu, karakterler ve ayarlar.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return MenuScaffold(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final kafa = store.selectedKafa;
          return Stack(
            children: [
              Positioned(top: 12, right: 12, child: StarBadge(store.totalStars)),
              Positioned(
                top: 6,
                left: 6,
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GameTitle('UÇAN', fontSize: 58),
                      const GameTitle('KAFALAR', fontSize: 46),
                      const SizedBox(height: 10),
                      KafaView(kafa, size: 130),
                      Text(
                        kafa.name,
                        style: const TextStyle(color: AppColors.ink, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 20),
                      _ModeButton(
                        mode: GameMode.fly,
                        icon: Icons.flight_takeoff_rounded,
                        color: AppColors.coral,
                        best: store.bestScore(GameMode.fly),
                      ),
                      const SizedBox(height: 14),
                      _ModeButton(
                        mode: GameMode.jump,
                        icon: Icons.rocket_launch_rounded,
                        color: AppColors.teal,
                        best: store.bestScore(GameMode.jump),
                      ),
                      const SizedBox(height: 14),
                      MenuButton(
                        label: 'Kafalar',
                        icon: Icons.face_retouching_natural,
                        color: AppColors.violet,
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CharacterScreen())),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.mode, required this.icon, required this.color, required this.best});

  final GameMode mode;
  final IconData icon;
  final Color color;
  final int best;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuButton(
          label: mode.label.toUpperCase(),
          icon: icon,
          color: color,
          height: 64,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(mode: mode))),
        ),
        const SizedBox(height: 4),
        Text(
          'Rekor: $best',
          style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}
