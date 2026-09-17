import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Kafanın üstündeki aksesuar / saç tipi.
enum KafaTop { spiky, cap, fluffy, crown, beanie, bow, horns, nightcap, captain, headband }

/// Göz tipi.
enum KafaEyes { round, happy, sleepy, glasses, star }

/// Ağız tipi.
enum KafaMouth { smile, open, tongue, o }

/// Oyunun orijinal karakterleri ("kafalar"). Tamamen kodla çizilir; hiçbir
/// gerçek kişiye ya da başka bir oyuna ait görsel kullanılmaz.
class Kafa {
  const Kafa({
    required this.id,
    required this.name,
    required this.price,
    required this.face,
    required this.top,
    required this.topColor,
    required this.eyes,
    required this.mouth,
    this.blush = true,
  });

  /// 1-tabanlı numara; müzik dosyasıyla eşleşir (background_music_N.mp3).
  final int id;
  final String name;

  /// Açılması için gereken TOPLAM yıldız (iki moddan toplanan).
  final int price;

  final Color face;
  final KafaTop top;
  final Color topColor;
  final KafaEyes eyes;
  final KafaMouth mouth;
  final bool blush;

  String get musicPath => 'background_music_$id.mp3';
}

const List<Kafa> kKafalar = [
  Kafa(id: 1, name: 'Pofuduk', price: 0, face: Color(0xFFFFD34E), top: KafaTop.spiky, topColor: Color(0xFFFF7A2F), eyes: KafaEyes.round, mouth: KafaMouth.smile),
  Kafa(id: 2, name: 'Zıpır', price: 10, face: Color(0xFF7BE3B6), top: KafaTop.cap, topColor: Color(0xFFE8413C), eyes: KafaEyes.happy, mouth: KafaMouth.tongue),
  Kafa(id: 3, name: 'Pamuk', price: 25, face: Color(0xFFFFA8C9), top: KafaTop.fluffy, topColor: Color(0xFFFFFFFF), eyes: KafaEyes.sleepy, mouth: KafaMouth.smile),
  Kafa(id: 4, name: 'Şimşek', price: 45, face: Color(0xFF6EC1FF), top: KafaTop.headband, topColor: Color(0xFFFFE03A), eyes: KafaEyes.glasses, mouth: KafaMouth.open),
  Kafa(id: 5, name: 'Fındık', price: 70, face: Color(0xFFD9A066), top: KafaTop.beanie, topColor: Color(0xFF2FA968), eyes: KafaEyes.round, mouth: KafaMouth.open),
  Kafa(id: 6, name: 'Bıcır', price: 100, face: Color(0xFFC7A6FF), top: KafaTop.bow, topColor: Color(0xFFFF4F7B), eyes: KafaEyes.round, mouth: KafaMouth.smile),
  Kafa(id: 7, name: 'Tosun', price: 140, face: Color(0xFFFF9F5A), top: KafaTop.horns, topColor: Color(0xFF8C98A8), eyes: KafaEyes.happy, mouth: KafaMouth.open, blush: false),
  Kafa(id: 8, name: 'Uykucu', price: 190, face: Color(0xFF5ED6CF), top: KafaTop.nightcap, topColor: Color(0xFF4A5BD9), eyes: KafaEyes.sleepy, mouth: KafaMouth.o),
  Kafa(id: 9, name: 'Kaptan', price: 250, face: Color(0xFFA5E86B), top: KafaTop.captain, topColor: Color(0xFF1F2A5C), eyes: KafaEyes.star, mouth: KafaMouth.smile),
  Kafa(id: 10, name: 'Kral Kafa', price: 320, face: Color(0xFFFFC23D), top: KafaTop.crown, topColor: Color(0xFFFFB300), eyes: KafaEyes.glasses, mouth: KafaMouth.smile),
];

Kafa kafaById(int id) =>
    kKafalar.firstWhere((k) => k.id == id, orElse: () => kKafalar.first);

const Color _ink = Color(0xFF2B2140);

/// Kafayı [box] karesinin içine çizer (kare değilse kısa kenar kullanılır).
void paintKafa(Canvas canvas, Rect box, Kafa k) {
  final s = min(box.width, box.height);
  canvas.save();
  canvas.translate(box.center.dx - s / 2, box.center.dy - s / 2);
  canvas.scale(s);

  const c = Offset(0.5, 0.57);
  const r = 0.37;
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = _ink;

  // Arkada kalan aksesuar parçaları (kafanın altında).
  _paintTopBack(canvas, k, c, r, outline);

  // Kafa: sol üstten aydınlatılmış yuvarlak.
  final headRect = Rect.fromCircle(center: c, radius: r);
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 1.0,
        colors: [Color.lerp(k.face, Colors.white, 0.35)!, k.face, Color.lerp(k.face, _ink, 0.18)!],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(headRect),
  );
  canvas.drawCircle(c, r, outline);

  if (k.blush) {
    final blush = Paint()..color = const Color(0x55FF5A7A);
    for (final sx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(sx * 0.225, 0.075), width: 0.12, height: 0.07),
        blush,
      );
    }
  }

  _paintEyes(canvas, k, c);
  _paintMouth(canvas, k, c);
  _paintTopFront(canvas, k, c, r, outline);

  canvas.restore();
}

Paint _stroke(double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = _ink;

Paint _fill(Color color) => Paint()..color = color;

void _paintEyes(Canvas canvas, Kafa k, Offset c) {
  final white = _fill(Colors.white);
  final pupil = _fill(_ink);
  for (final sx in [-1.0, 1.0]) {
    final e = c + Offset(sx * 0.135, -0.04);
    switch (k.eyes) {
      case KafaEyes.round:
        canvas.drawCircle(e, 0.075, white);
        canvas.drawCircle(e, 0.075, _stroke(0.025));
        canvas.drawCircle(e + const Offset(0.012, 0.01), 0.042, pupil);
        canvas.drawCircle(e + const Offset(-0.004, -0.012), 0.014, white);
      case KafaEyes.happy:
        canvas.drawArc(Rect.fromCircle(center: e + const Offset(0, 0.03), radius: 0.055), pi * 1.1, pi * 0.8,
            false, _stroke(0.035));
      case KafaEyes.sleepy:
        canvas.drawArc(Rect.fromCircle(center: e - const Offset(0, 0.02), radius: 0.055), pi * 0.15, pi * 0.7,
            false, _stroke(0.032));
      case KafaEyes.glasses:
        canvas.drawCircle(e, 0.085, _fill(const Color(0xCCFFFFFF)));
        canvas.drawCircle(e + const Offset(0.008, 0.008), 0.036, pupil);
        canvas.drawCircle(e, 0.085, _stroke(0.03));
      case KafaEyes.star:
        final p = starPath(e, 0.08, 0.036);
        canvas.drawPath(p, _fill(const Color(0xFFFFE45C)));
        canvas.drawPath(p, _stroke(0.022));
    }
  }
  if (k.eyes == KafaEyes.glasses) {
    canvas.drawLine(c + const Offset(-0.05, -0.05), c + const Offset(0.05, -0.05), _stroke(0.03));
  }
}

void _paintMouth(Canvas canvas, Kafa k, Offset c) {
  final m = c + const Offset(0, 0.13);
  final smileRect = Rect.fromCenter(center: m - const Offset(0, 0.03), width: 0.2, height: 0.12);
  switch (k.mouth) {
    case KafaMouth.smile:
      canvas.drawArc(smileRect, pi * 0.12, pi * 0.76, false, _stroke(0.035));
    case KafaMouth.open:
      final rect = Rect.fromCenter(center: m - const Offset(0, 0.005), width: 0.19, height: 0.14);
      final path = Path()
        ..addArc(rect, 0, pi)
        ..close();
      canvas.drawPath(path, _fill(const Color(0xFF8E2344)));
      canvas.save();
      canvas.clipPath(path);
      canvas.drawCircle(m + const Offset(0, 0.075), 0.06, _fill(const Color(0xFFFF7A99)));
      canvas.restore();
      canvas.drawPath(path, _stroke(0.028));
    case KafaMouth.tongue:
      canvas.drawCircle(m + const Offset(0.035, 0.035), 0.035, _fill(const Color(0xFFFF7A99)));
      canvas.drawCircle(m + const Offset(0.035, 0.035), 0.035, _stroke(0.022));
      canvas.drawArc(smileRect, pi * 0.12, pi * 0.76, false, _stroke(0.035));
    case KafaMouth.o:
      final rect = Rect.fromCenter(center: m, width: 0.07, height: 0.08);
      canvas.drawOval(rect, _fill(const Color(0xFF8E2344)));
      canvas.drawOval(rect, _stroke(0.025));
  }
}

/// Kafanın ARKASINDA kalan aksesuar parçaları.
void _paintTopBack(Canvas canvas, Kafa k, Offset c, double r, Paint outline) {
  switch (k.top) {
    case KafaTop.spiky:
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final a = pi + pi * (0.12 + i * 0.19);
        final base1 = c + Offset(cos(a - 0.22) * r * 0.92, sin(a - 0.22) * r * 0.92);
        final base2 = c + Offset(cos(a + 0.22) * r * 0.92, sin(a + 0.22) * r * 0.92);
        final tip = c + Offset(cos(a) * r * 1.42, sin(a) * r * 1.42);
        path
          ..moveTo(base1.dx, base1.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(base2.dx, base2.dy)
          ..close();
      }
      canvas.drawPath(path, _fill(k.topColor));
      canvas.drawPath(path, outline);
    case KafaTop.fluffy:
      for (var i = 0; i < 7; i++) {
        final a = pi + pi * (0.02 + i * 0.16);
        final p = c + Offset(cos(a) * r * 0.95, sin(a) * r * 0.95);
        canvas.drawCircle(p, 0.1, _fill(k.topColor));
        canvas.drawCircle(p, 0.1, outline);
      }
    case KafaTop.horns:
      for (final sx in [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(c.dx + sx * 0.22, c.dy - 0.24)
          ..quadraticBezierTo(c.dx + sx * 0.5, c.dy - 0.34, c.dx + sx * 0.44, c.dy - 0.6)
          ..quadraticBezierTo(c.dx + sx * 0.36, c.dy - 0.38, c.dx + sx * 0.12, c.dy - 0.32)
          ..close();
        canvas.drawPath(path, _fill(const Color(0xFFFFF1D0)));
        canvas.drawPath(path, outline);
      }
    case KafaTop.headband:
      for (final dy in [0.0, 0.07]) {
        final path = Path()
          ..moveTo(c.dx + 0.33, c.dy - 0.2)
          ..quadraticBezierTo(c.dx + 0.5, c.dy - 0.22 + dy, c.dx + 0.56, c.dy - 0.08 + dy)
          ..lineTo(c.dx + 0.48, c.dy - 0.1 + dy)
          ..close();
        canvas.drawPath(path, _fill(k.topColor));
        canvas.drawPath(path, outline);
      }
    default:
      break;
  }
}

/// Kafa yuvarlağının üst yarısını (kubbe) veren yol.
Path _dome(Offset c, double radius) {
  return Path()
    ..addArc(Rect.fromCircle(center: c, radius: radius), pi, pi)
    ..close();
}

/// Kafanın ÖNÜNDE kalan aksesuar parçaları.
void _paintTopFront(Canvas canvas, Kafa k, Offset c, double r, Paint outline) {
  switch (k.top) {
    case KafaTop.cap:
      final dome = _dome(c - const Offset(0, 0.13), r * 0.9);
      canvas.drawPath(dome, _fill(k.topColor));
      canvas.drawPath(dome, outline);
      final brim = RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - 0.05, c.dy - 0.16, 0.46, 0.08), const Radius.circular(0.04));
      canvas.drawRRect(brim, _fill(Color.lerp(k.topColor, _ink, 0.2)!));
      canvas.drawRRect(brim, outline);
      canvas.drawCircle(c - const Offset(0, 0.46), 0.035, _fill(Colors.white));
    case KafaTop.crown:
      final base = c.dy - r * 0.78;
      final path = Path()
        ..moveTo(c.dx - 0.24, base)
        ..lineTo(c.dx - 0.27, base - 0.2)
        ..lineTo(c.dx - 0.14, base - 0.09)
        ..lineTo(c.dx, base - 0.24)
        ..lineTo(c.dx + 0.14, base - 0.09)
        ..lineTo(c.dx + 0.27, base - 0.2)
        ..lineTo(c.dx + 0.24, base)
        ..close();
      canvas.drawPath(path, _fill(k.topColor));
      canvas.drawPath(path, outline);
      for (final p in [
        Offset(c.dx - 0.13, base - 0.04),
        Offset(c.dx, base - 0.05),
        Offset(c.dx + 0.13, base - 0.04),
      ]) {
        canvas.drawCircle(p, 0.026, _fill(const Color(0xFFE8413C)));
      }
    case KafaTop.beanie:
      final dome = _dome(c - const Offset(0, 0.14), r * 0.92);
      canvas.drawPath(dome, _fill(k.topColor));
      canvas.drawPath(dome, outline);
      final band = RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - r * 0.95, c.dy - 0.2, r * 1.9, 0.09), const Radius.circular(0.04));
      canvas.drawRRect(band, _fill(Color.lerp(k.topColor, Colors.white, 0.35)!));
      canvas.drawRRect(band, outline);
      canvas.drawCircle(c - const Offset(0, 0.54), 0.07, _fill(Colors.white));
      canvas.drawCircle(c - const Offset(0, 0.54), 0.07, outline);
    case KafaTop.bow:
      final knot = c + const Offset(0.2, -0.32);
      for (final sx in [-1.0, 1.0]) {
        final wing = Path()
          ..moveTo(knot.dx, knot.dy)
          ..lineTo(knot.dx + sx * 0.17, knot.dy - 0.1)
          ..lineTo(knot.dx + sx * 0.17, knot.dy + 0.1)
          ..close();
        canvas.drawPath(wing, _fill(k.topColor));
        canvas.drawPath(wing, outline);
      }
      canvas.drawCircle(knot, 0.045, _fill(Color.lerp(k.topColor, _ink, 0.15)!));
      canvas.drawCircle(knot, 0.045, outline);
    case KafaTop.horns:
      final helmet = _dome(c - const Offset(0, 0.12), r * 0.92);
      canvas.drawPath(helmet, _fill(k.topColor));
      canvas.drawPath(helmet, outline);
      for (var i = -2; i <= 2; i++) {
        canvas.drawCircle(
            c + Offset(i * 0.1, -0.16 - (i.abs() == 2 ? 0.03 : 0)), 0.018, _fill(const Color(0xFFD7DEE8)));
      }
    case KafaTop.nightcap:
      final path = Path()
        ..moveTo(c.dx - r * 0.95, c.dy - 0.12)
        ..quadraticBezierTo(c.dx - 0.05, c.dy - 0.75, c.dx + 0.42, c.dy - 0.5)
        ..quadraticBezierTo(c.dx + 0.2, c.dy - 0.35, c.dx + r * 0.95, c.dy - 0.12)
        ..close();
      canvas.drawPath(path, _fill(k.topColor));
      canvas.save();
      canvas.clipPath(path);
      final stripe = Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 0.05;
      for (var i = 0; i < 6; i++) {
        canvas.drawLine(
            Offset(c.dx - 0.5 + i * 0.18, c.dy), Offset(c.dx - 0.2 + i * 0.18, c.dy - 0.8), stripe);
      }
      canvas.restore();
      canvas.drawPath(path, outline);
      canvas.drawCircle(Offset(c.dx + 0.44, c.dy - 0.48), 0.065, _fill(Colors.white));
      canvas.drawCircle(Offset(c.dx + 0.44, c.dy - 0.48), 0.065, outline);
    case KafaTop.captain:
      final hat = Path()
        ..moveTo(c.dx - 0.3, c.dy - 0.22)
        ..lineTo(c.dx - 0.36, c.dy - 0.5)
        ..quadraticBezierTo(c.dx, c.dy - 0.62, c.dx + 0.36, c.dy - 0.5)
        ..lineTo(c.dx + 0.3, c.dy - 0.22)
        ..close();
      canvas.drawPath(hat, _fill(Colors.white));
      canvas.drawPath(hat, outline);
      final band = Rect.fromLTWH(c.dx - 0.32, c.dy - 0.3, 0.64, 0.1);
      canvas.drawRect(band, _fill(k.topColor));
      canvas.drawRect(band, outline);
      final visor =
          RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - 0.34, c.dy - 0.22, 0.68, 0.07), const Radius.circular(0.035));
      canvas.drawRRect(visor, _fill(k.topColor));
      canvas.drawRRect(visor, outline);
      canvas.drawPath(starPath(Offset(c.dx, c.dy - 0.41), 0.06, 0.027), _fill(const Color(0xFFFFC83D)));
    case KafaTop.headband:
      // Dikenli saç tutamı (bandın üstünde).
      final tuft = Path()
        ..moveTo(c.dx - 0.2, c.dy - 0.31)
        ..lineTo(c.dx - 0.13, c.dy - 0.48)
        ..lineTo(c.dx - 0.04, c.dy - 0.34)
        ..lineTo(c.dx + 0.05, c.dy - 0.52)
        ..lineTo(c.dx + 0.12, c.dy - 0.34)
        ..lineTo(c.dx + 0.22, c.dy - 0.46)
        ..lineTo(c.dx + 0.24, c.dy - 0.29)
        ..close();
      canvas.drawPath(tuft, _fill(const Color(0xFF3A3F8F)));
      canvas.drawPath(tuft, outline);
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
      canvas.drawRect(Rect.fromLTWH(c.dx - r, c.dy - 0.25, r * 2, 0.1), _fill(k.topColor));
      canvas.restore();
      for (final dy in [-0.25, -0.15]) {
        final half = sqrt(r * r - dy * dy) - 0.01;
        canvas.drawLine(Offset(c.dx - half, c.dy + dy), Offset(c.dx + half, c.dy + dy), _stroke(0.02));
      }
    default:
      break;
  }
}

/// [center] etrafında 5 köşeli yıldız yolu (dış yarıçap [outer], iç [inner]).
Path starPath(Offset center, double outer, double inner) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rad = i.isEven ? outer : inner;
    final a = -pi / 2 + i * pi / 5;
    final p = center + Offset(cos(a) * rad, sin(a) * rad);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

/// Kafayı [pixelSize] x [pixelSize] bir görüntüye çizer (oyun içi sprite için;
/// her karede yeniden çizmek yerine bir kez rasterlanır).
ui.Image renderKafaImage(Kafa k, int pixelSize) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paintKafa(canvas, Rect.fromLTWH(0, 0, pixelSize.toDouble(), pixelSize.toDouble()), k);
  return recorder.endRecording().toImageSync(pixelSize, pixelSize);
}

/// Flutter arayüzünde kafa gösteren widget. [locked] ise gri ve soluk.
class KafaView extends StatelessWidget {
  const KafaView(this.kafa, {super.key, this.size = 96, this.locked = false});

  final Kafa kafa;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final view = CustomPaint(size: Size.square(size), painter: _KafaPainter(kafa));
    if (!locked) return view;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 0.55, 0,
      ]),
      child: view,
    );
  }
}

class _KafaPainter extends CustomPainter {
  _KafaPainter(this.kafa);
  final Kafa kafa;

  @override
  void paint(Canvas canvas, Size size) => paintKafa(canvas, Offset.zero & size, kafa);

  @override
  bool shouldRepaint(_KafaPainter old) => old.kafa != kafa;
}
