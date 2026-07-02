import 'package:flutter/material.dart';

import 'menu_screen.dart';

/// Geri/menü dönüşü: geri gidilebiliyorsa geri gider, ekran en alttaysa
/// (ör. doğrudan açıldıysa) menüyü açar. Boş stack'e düşüp siyah ekranı önler.
void goBackOrMenu(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    nav.pushReplacement(MaterialPageRoute(builder: (_) => const MenuScreen()));
  }
}

/// Uygulama genelinde tutarlı görünüm için ortak renkler ve widget'lar.
class AppColors {
  static const sky = Color(0xFF70C5CE);
  static const grass = Color(0xFF73C736);
  static const grassDark = Color(0xFF5A9B2A);
  static const sand = Color(0xFFDED895);
  static const orange = Color(0xFFF39C12);
  static const dark = Color(0xFF3B3B3B);
}

/// Retro/arcade hissi veren kalın gölgeli başlık.
class GameTitle extends StatelessWidget {
  const GameTitle(this.text, {super.key, this.fontSize = 40});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
    );
  }
}

/// Menülerde kullanılan büyük, renkli buton.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.grass,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
        ),
        // Uzun etiketler sabit genişliği taşmasın diye içerik küçültülerek sığdırılır.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 26), const SizedBox(width: 10)],
              Text(
                label,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menü arka planını (menu_background.jpg) tam ekran gösteren sarmalayıcı.
class MenuScaffold extends StatelessWidget {
  const MenuScaffold({super.key, required this.child, this.showBackground = true});

  final Widget child;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: showBackground
            ? const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/menu_background.jpg'),
                  fit: BoxFit.cover,
                ),
              )
            : const BoxDecoration(color: AppColors.sky),
        child: SafeArea(child: child),
      ),
    );
  }
}
