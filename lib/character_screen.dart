import 'package:flutter/material.dart';

import 'ad_service.dart';
import 'game_store.dart';
import 'kafa.dart';
import 'ui_common.dart';

/// Kafa seçim ekranı. Kafalar iki moddan toplanan TOPLAM yıldızla açılır.
class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  bool _watchingAd = false;

  Future<void> _watchAdForStars() async {
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    final rewarded = await AdService.instance.showRewarded();
    if (!mounted) return;
    if (!rewarded) {
      setState(() => _watchingAd = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam henüz hazır değil. Biraz sonra tekrar dene.'),
        ),
      );
      return;
    }

    final unlocked = await GameStore.instance.addRewardedStars();
    if (!mounted) return;
    setState(() => _watchingAd = false);
    final suffix = unlocked.isEmpty
        ? ''
        : ' • ${unlocked.map((k) => k.name).join(', ')} açıldı!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '+${GameStore.rewardedStarAmount} yıldız kazandın!$suffix',
        ),
      ),
    );
  }

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
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => goBackOrMenu(context),
                  ),
                  const Expanded(child: GameTitle('Kafalar', fontSize: 32)),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: StarBadge(store.totalStars),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Uç ve Zıpla modlarında yıldız topla, yeni kafaları aç!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _watchingAd ? null : _watchAdForStars,
                    icon: _watchingAd
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.ondemand_video_rounded),
                    label: Text(
                      _watchingAd
                          ? 'Reklam açılıyor...'
                          : 'Reklam İzle  •  +${GameStore.rewardedStarAmount} Yıldız',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.coral.withValues(
                        alpha: 0.55,
                      ),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: AppColors.ink,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
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
  const _KafaTile({
    required this.kafa,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

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
          border: Border.all(
            color: selected ? AppColors.coral : AppColors.ink,
            width: selected ? 4 : 2.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, c) => KafaView(
                      kafa,
                      size: c.biggest.shortestSide * 0.95,
                      locked: !unlocked,
                    ),
                  ),
                  if (!unlocked)
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.ink,
                      size: 30,
                    ),
                  if (selected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.coral,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: unlocked
                  ? Text(
                      kafa.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.gold,
                          size: 16,
                        ),
                        Text(
                          '${kafa.price}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
