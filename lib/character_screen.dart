import 'package:flutter/material.dart';

import 'game_store.dart';
import 'ui_common.dart';

/// Karakter seçim ekranı. Kilitli karakterler görselleriyle birlikte
/// karartılmış olarak, üzerinde kilit simgesi ve gereken puanla gösterilir.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return MenuScaffold(
      showBackground: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => goBackOrMenu(context),
                  ),
                  const Expanded(child: GameTitle('Karakterler', fontSize: 30)),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Her ${store.difficulty.unlockInterval} puanda yeni karakter açılır (${store.difficulty.label})',
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: kCharacters.length,
                  itemBuilder: (context, index) {
                    final info = kCharacters[index];
                    final unlocked = store.isUnlocked(info.id);
                    final selected = store.selectedCharacter == info.id;
                    return _CharacterTile(
                      info: info,
                      unlocked: unlocked,
                      selected: selected,
                      threshold: store.unlockThreshold(info.id),
                      onTap: unlocked
                          ? () => store.selectCharacter(info.id)
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({
    required this.info,
    required this.unlocked,
    required this.selected,
    required this.threshold,
    required this.onTap,
  });

  final CharacterInfo info;
  final bool unlocked;
  final bool selected;
  final int threshold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.orange : Colors.white,
            width: selected ? 4 : 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: ColorFiltered(
                      colorFilter: unlocked
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.mode(
                              Colors.black54, BlendMode.saturation),
                      child: Image.asset(
                        'assets/images/characters/character_${info.id}.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (!unlocked)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: Icon(Icons.lock, color: Colors.white, size: 34),
                      ),
                    ),
                  if (selected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(Icons.check_circle,
                          color: AppColors.orange, size: 24),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                unlocked ? info.displayName : '$threshold puan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? AppColors.dark : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
