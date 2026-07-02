import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ad_service.dart';
import 'character_screen.dart';
import 'game_screen.dart';
import 'game_store.dart';
import 'menu_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await GameStore.instance.load();
  // Reklamları başlat (web/masaüstünde no-op). UI'ı bloklamaması için await yok.
  AdService.instance.initialize();
  runApp(const FlappyApp());
}

/// Sadece debug modunda: `?screen=character|settings|game` ile doğrudan ilgili
/// ekranı açar (görsel test/hızlı geliştirme için). Release'de her zaman menü.
Widget _initialScreen() {
  if (kDebugMode) {
    switch (Uri.base.queryParameters['screen']) {
      case 'character':
        return const CharacterScreen();
      case 'settings':
        return const SettingsScreen();
      case 'game':
        return const GameScreen();
    }
  }
  return const MenuScreen();
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uçan Kafalar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF73C736)),
        useMaterial3: true,
      ),
      home: _initialScreen(),
    );
  }
}
