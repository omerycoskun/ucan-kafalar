import 'package:flutter/material.dart';

import 'game_store.dart';
import 'ui_common.dart';

/// Ayarlar menüsü: ses/müzik aç-kapa, zorluk seçimi, varsayılana sıfırlama.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  const Expanded(child: GameTitle('Ayarlar', fontSize: 30)),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _card(
                      child: SwitchListTile(
                        title: const _Label('Ses Efektleri'),
                        secondary: const Icon(Icons.volume_up, color: Colors.white),
                        value: store.soundOn,
                        activeThumbColor: AppColors.grass,
                        onChanged: store.setSoundOn,
                      ),
                    ),
                    _card(
                      child: SwitchListTile(
                        title: const _Label('Müzik'),
                        secondary: const Icon(Icons.music_note, color: Colors.white),
                        value: store.musicOn,
                        activeThumbColor: AppColors.grass,
                        onChanged: store.setMusicOn,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 6),
                      child: _Label('Zorluk', bold: true),
                    ),
                    RadioGroup<Difficulty>(
                      groupValue: store.difficulty,
                      onChanged: (v) {
                        if (v != null) store.setDifficulty(v);
                      },
                      child: Column(
                        children: Difficulty.values
                            .map(
                              (d) => _card(
                                child: RadioListTile<Difficulty>(
                                  title: _Label(d.label),
                                  subtitle: Text(
                                    d.subtitle,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  value: d,
                                  activeColor: AppColors.orange,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: MenuButton(
                        label: 'Varsayılana Sıfırla',
                        icon: Icons.restore,
                        color: AppColors.orange,
                        onPressed: () async {
                          await store.resetToDefaults();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ayarlar sıfırlandı'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: bold ? FontWeight.bold : FontWeight.w600,
      ),
    );
  }
}
