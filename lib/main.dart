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
  runApp(const UcanKafalarApp());
  // iOS ATT izin penceresi uygulama AKTİF olduğunda açılabilir; bu yüzden
  // reklam başlatma (önce ATT izni ister) ilk kare çizildikten sonra yapılır.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService.instance.initialize();
  });
}

/// Sadece debug modunda: `?screen=character|settings|fly|jump` ile doğrudan ilgili
/// ekranı açar (görsel test/hızlı geliştirme için). Release'de her zaman menü.
Widget _initialScreen() {
  if (kDebugMode) {
    switch (Uri.base.queryParameters['screen']) {
      case 'character':
        return const CharacterScreen();
      case 'settings':
        return const SettingsScreen();
      case 'fly':
        return const GameScreen(mode: GameMode.fly);
      case 'jump':
        return const GameScreen(mode: GameMode.jump);
    }
  }
  return const MenuScreen();
}

class UcanKafalarApp extends StatelessWidget {
  const UcanKafalarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uçan Kafalar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5BD6)),
        useMaterial3: true,
      ),
      home: _initialScreen(),
    );
  }
}
