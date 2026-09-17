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

/// Uygulama genelinde tutarlı görünüm için ortak renkler.
class AppColors {
  static const skyTop = Color(0xFF4FA8FF);
  static const skyBottom = Color(0xFFFFD9A8);
  static const violet = Color(0xFF6B5BD6);
  static const coral = Color(0xFFFF7B6B);
  static const teal = Color(0xFF2FB8B0);
  static const gold = Color(0xFFFFC83D);
  static const panel = Color(0xFFFFF4E0);
  static const ink = Color(0xFF2B2140);
}

/// Kalın gölgeli oyun başlığı.
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
        letterSpacing: 1.5,
        shadows: const [Shadow(color: AppColors.ink, offset: Offset(3, 4), blurRadius: 0)],
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
    this.color = AppColors.violet,
    this.width = 250,
    this.height = 58,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.ink, width: 3),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 26), const SizedBox(width: 10)],
              Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toplam yıldız rozeti.
class StarBadge extends StatelessWidget {
  const StarBadge(this.stars, {super.key});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: 4),
          Text('$stars', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        ],
      ),
    );
  }
}

/// Tüm menü ekranlarının kodla çizilmiş gökyüzü arka planı.
class MenuScaffold extends StatelessWidget {
  const MenuScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyTop, Color(0xFF9ED8FF), AppColors.skyBottom],
          ),
        ),
        child: CustomPaint(
          painter: _CloudsPainter(),
          child: SafeArea(child: child),
        ),
      ),
    );
  }
}

class _CloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.75);
    void cloud(double x, double y, double s) {
      canvas.drawCircle(Offset(x, y), 22 * s, p);
      canvas.drawCircle(Offset(x + 26 * s, y - 10 * s), 28 * s, p);
      canvas.drawCircle(Offset(x + 54 * s, y), 20 * s, p);
    }

    cloud(size.width * 0.08, size.height * 0.12, 1.0);
    cloud(size.width * 0.68, size.height * 0.22, 0.8);
    cloud(size.width * 0.18, size.height * 0.78, 1.2);
    cloud(size.width * 0.72, size.height * 0.9, 0.9);
  }

  @override
  bool shouldRepaint(_CloudsPainter oldDelegate) => false;
}
