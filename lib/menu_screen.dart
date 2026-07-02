import 'package:flutter/material.dart';

import 'character_screen.dart';
import 'game_screen.dart';
import 'game_store.dart';
import 'settings_screen.dart';
import 'ui_common.dart';

/// Ana menü: oyna, karakterler, ayarlar + en iyi skor / seçili karakter özeti.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return MenuScaffold(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GameTitle('UÇAN', fontSize: 56),
                const GameTitle('KAFALAR', fontSize: 46),
                const SizedBox(height: 8),
                _infoBadge(store),
                const SizedBox(height: 28),
                MenuButton(
                  label: 'OYNA',
                  icon: Icons.play_arrow,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                MenuButton(
                  label: 'Karakterler',
                  icon: Icons.people,
                  color: AppColors.orange,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CharacterScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                MenuButton(
                  label: 'Ayarlar',
                  icon: Icons.settings,
                  color: AppColors.orange,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoBadge(GameStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            'En İyi: ${store.bestScore}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.person, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          Text(
            'Karakter ${store.selectedCharacter}  •  ${store.difficulty.label}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
