import 'package:flutter/material.dart';

import 'game_store.dart';
import 'kafa.dart';
import 'ui_common.dart';

/// Kafa seçim ekranı. Kafalar iki moddan toplanan TOPLAM yıldızla açılır.
class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GameStore.instance;
    return MenuScaffold(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 32),
                    onPressed: () => goBackOrMenu(context),
                  ),
                  const Expanded(child: GameTitle('Kafalar', fontSize: 32)),
                  Padding(padding: const EdgeInsets.only(right: 12), child: StarBadge(store.totalStars)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Uç ve Zıpla modlarında yıldız topla, yeni kafaları aç!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: kKafalar.length,
                  itemBuilder: (context, index) {
                    final k = kKafalar[index];
                    final unlocked = store.isUnlocked(k);
                    return _KafaTile(
                      kafa: k,
                      unlocked: unlocked,
                      selected: store.selectedKafa.id == k.id,
                      onTap: unlocked ? () => store.selectKafa(k) : null,
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

class _KafaTile extends StatelessWidget {
  const _KafaTile({required this.kafa, required this.unlocked, required this.selected, required this.onTap});

  final Kafa kafa;
  final bool unlocked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.coral : AppColors.ink, width: selected ? 4 : 2.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, c) => KafaView(kafa, size: c.biggest.shortestSide * 0.95, locked: !unlocked),
                  ),
                  if (!unlocked) const Icon(Icons.lock_rounded, color: AppColors.ink, size: 30),
                  if (selected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(Icons.check_circle_rounded, color: AppColors.coral, size: 24),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: unlocked
                  ? Text(kafa.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                        Text('${kafa.price}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
