// Uygulama ikonu ve açılış logosunu karakter çiziminden üretir.
// Çalıştır: flutter test tool/render_icons_test.dart
// Çıktı: assets/icon/app_icon.png (1024, opak) + assets/icon/splash_logo.png (1024, şeffaf)
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flappybird/kafa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _s = 1024;

void _star(Canvas canvas, Offset c, double r, double rot) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(rot);
  final p = starPath(Offset.zero, r, r * 0.46);
  canvas.drawPath(p, Paint()..color = const Color(0xFFFFCD28));
  canvas.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2B2140),
  );
  canvas.restore();
}

void _tower(Canvas canvas, Rect r, Color body, Color cap, {required bool capAtBottom}) {
  const ink = Color(0xFF2B2140);
  canvas.drawRect(r, Paint()..color = body);
  final mortar = Paint()
    ..color = Colors.black.withValues(alpha: 0.18)
    ..strokeWidth = 8;
  var row = 0;
  for (double y = r.top; y < r.bottom; y += 48, row++) {
    canvas.drawLine(Offset(r.left, y), Offset(r.right, y), mortar);
    for (double x = r.left + (row.isEven ? 0 : 45); x < r.right; x += 90) {
      canvas.drawLine(Offset(x, y), Offset(x, min(y + 48, r.bottom)), mortar);
    }
  }
  final edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 14
    ..color = ink;
  canvas.drawRect(r, edge);
  final capRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(r.left - 22, capAtBottom ? r.bottom - 70 : r.top, r.width + 44, 70),
    const Radius.circular(24),
  );
  canvas.drawRRect(capRect, Paint()..color = cap);
  canvas.drawRRect(capRect, edge);
}

Future<void> _save(ui.Picture picture, String path) async {
  final img = await picture.toImage(_s.toInt(), _s.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('ikonları üret', (tester) async {
    await tester.runAsync(() async {
      final kafa = kKafalar.first;

      // --- App icon (opak, kare) ---
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      const full = Rect.fromLTWH(0, 0, _s, _s);
      canvas.drawRect(
        full,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FA8FF), Color(0xFF9ED8FF), Color(0xFFFFD9A8)],
          ).createShader(full),
      );
      final cloud = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(const Offset(150, 230), 70, cloud);
      canvas.drawCircle(const Offset(240, 200), 90, cloud);
      canvas.drawCircle(const Offset(330, 240), 62, cloud);
      _tower(canvas, const Rect.fromLTWH(790, -20, 180, 300), const Color(0xFF9B7BFF), const Color(0xFFC9B6FF),
          capAtBottom: true);
      _tower(canvas, const Rect.fromLTWH(790, 760, 180, 300), const Color(0xFF9B7BFF), const Color(0xFFC9B6FF),
          capAtBottom: false);
      _star(canvas, const Offset(880, 520), 70, 0.2);
      _star(canvas, const Offset(170, 820), 52, -0.25);
      paintKafa(canvas, const Rect.fromLTWH(150, 170, 700, 700), kafa);
      await _save(rec.endRecording(), 'assets/icon/app_icon.png');

      // --- Splash logosu (şeffaf; arka plan rengi splash ayarından) ---
      final rec2 = ui.PictureRecorder();
      final c2 = Canvas(rec2);
      paintKafa(c2, const Rect.fromLTWH(262, 232, 500, 500), kafa);
      _star(c2, const Offset(720, 300), 56, 0.2);
      _star(c2, const Offset(300, 700), 42, -0.2);
      await _save(rec2.endRecording(), 'assets/icon/splash_logo.png');
    });
  });
}
