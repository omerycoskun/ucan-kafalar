// App Store ekran görüntülerini üretir (gerçek uygulama ekranları, gerçek oyun
// döngüsü; otopilot oynar). Çalıştır:
//   flutter test tool/screenshots_test.dart
// Çıktı: build/screenshots/{phone,ipad}_N.png
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flappybird/arcade.dart';
import 'package:flappybird/character_screen.dart';
import 'package:flappybird/flappy_game.dart';
import 'package:flappybird/game_store.dart';
import 'package:flappybird/jump_game.dart';
import 'package:flappybird/kafa.dart';
import 'package:flappybird/ledge.dart';
import 'package:flappybird/menu_screen.dart';
import 'package:flappybird/pipe.dart';
import 'package:flappybird/ui_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontDir = r'C:\src\flutter\bin\cache\artifacts\material_fonts';

Future<void> _loadFonts() async {
  Future<ByteData> f(String name) async => ByteData.sublistView(File('$_fontDir\\$name').readAsBytesSync());
  final roboto = FontLoader('Roboto')
    ..addFont(f('roboto-regular.ttf'))
    ..addFont(f('roboto-medium.ttf'))
    ..addFont(f('roboto-bold.ttf'))
    ..addFont(f('roboto-black.ttf'));
  await roboto.load();
  // Aile belirtmeyen metinler (ör. Flame TextPaint) testte "FlutterTest" kutu
  // fontuna düşer; aynı Roboto dosyalarını o adla da yükle.
  for (final family in ['FlutterTest', 'Ahem']) {
    await (FontLoader(family)
          ..addFont(f('roboto-black.ttf'))
          ..addFont(f('roboto-bold.ttf'))
          ..addFont(f('roboto-regular.ttf')))
        .load();
  }
  await (FontLoader('MaterialIcons')..addFont(f('materialicons-regular.otf'))).load();
}

class _Device {
  const _Device(this.name, this.physical, this.dpr);
  final String name;
  final Size physical;
  final double dpr;
}

const _devices = [
  _Device('phone', Size(1242, 2688), 3),
  _Device('ipad', Size(2048, 2732), 2),
];

final _boundary = GlobalKey();

Widget _frame(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: RepaintBoundary(key: _boundary, child: child),
    );

Future<void> _capture(WidgetTester tester, _Device d, int index) async {
  await tester.runAsync(() async {
    final ro = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: d.dpr);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/screenshots').createSync(recursive: true);
    File('build/screenshots/${d.name}_$index.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Oyun ekranının görünümü (reklam bandı hariç): oyun + duraklat butonu.
Widget _gameView(ArcadeGame game) => Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          GameWidget<ArcadeGame>(game: game),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: AppColors.ink.withValues(alpha: 0.55),
                  shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.pause_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

/// Asset görsellerini gerçek (async) ortamda önceden çöz; aksi halde testte
/// resimler boş çizilir ya da beklemede kalır.
Future<void> _precache(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final k in kKafalar) {
      await Flame.images.load(k.spritePath);
      final ctx = _boundary.currentContext;
      if (ctx != null && ctx.mounted) {
        await precacheImage(AssetImage(k.imageAsset), ctx);
      }
    }
  });
}

Future<void> _frames(WidgetTester tester, int n, void Function() each) async {
  for (var i = 0; i < n; i++) {
    each();
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final d in _devices) {
    testWidgets('screenshots ${d.name}', (tester) async {
      tester.view.physicalSize = d.physical;
      tester.view.devicePixelRatio = d.dpr;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({
        'total_stars': 148,
        'selected_kafa': 4,
        'best_fly': 37,
        'best_jump': 1260,
        'sound_on': false,
        'music_on': false,
      });
      await GameStore.instance.load();

      // 1) Ana menü
      await tester.pumpWidget(_frame(const MenuScreen()));
      await _precache(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await _capture(tester, d, 1);

      // 2) Uç modu: otopilot kulelerin boşluğunu hedefler.
      final fly = FlyGame(onGameOver: (_) {});
      await tester.pumpWidget(_frame(_gameView(fly)));
      await tester.pump(const Duration(milliseconds: 100));
      fly.startRun();
      var captured = false;
      for (var i = 0; i < 900 && !captured; i++) {
        if (fly.state == GameState.gameOver) fly.restart();
        if (fly.state == GameState.ready) {
          fly.startRun();
          fly.flyer.flap();
        }
        final towers = fly.world.children.whereType<TowerPair>().where((t) => t.position.x + TowerPair.towerWidth > fly.flyer.position.x - 20).toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
        final target = towers.isEmpty ? 330.0 : towers.first.gapY + 12;
        if (fly.flyer.position.y > target && fly.flyer.velocity > 0) fly.flyer.flap();
        await tester.pump(const Duration(milliseconds: 16));
        // Ekranda 2 kule, bir yıldız ve birkaç puan varken çek.
        final visibleTowers = fly.world.children.whereType<TowerPair>().where((t) => t.position.x < 380).length;
        final starVisible = fly.world.children.whereType<TowerPair>().any((t) => t.withStar && t.position.x > fly.flyer.position.x + 40 && t.position.x < 360);
        if (fly.score >= 4 && visibleTowers >= 2 && starVisible && fly.starsThisRun >= 2) captured = true;
      }
      await _capture(tester, d, 2);

      // 3) Zıpla modu: otopilot üstteki en yakın platforma yönelir.
      final jump = JumpGame(onGameOver: (_) {});
      await tester.pumpWidget(_frame(_gameView(jump)));
      await tester.pump(const Duration(milliseconds: 100));
      jump.startRun();
      jump.jumper.velocity.y = JumpGame.jumpVelocity;
      await _frames(tester, 420, () {
        if (jump.state == GameState.gameOver) {
          jump.restart();
          jump.startRun();
          jump.jumper.velocity.y = JumpGame.jumpVelocity;
        }
        final ledges = jump.world.children.whereType<Ledge>().where((l) => l.position.y < jump.jumper.position.y - 20).toList()
          ..sort((a, b) => b.position.y.compareTo(a.position.y));
        if (ledges.isNotEmpty) jump.aimAt(ledges.first.position.x);
      });
      await _capture(tester, d, 3);

      // 4) Kafalar ekranı
      await tester.pumpWidget(_frame(const CharacterScreen()));
      await _precache(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await _capture(tester, d, 4);

      await tester.pumpWidget(const SizedBox());
    });
  }
}
