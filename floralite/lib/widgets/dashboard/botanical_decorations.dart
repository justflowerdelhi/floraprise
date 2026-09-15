import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure vector custom painter that draws subtle, elegant botanical leaf silhouettes
/// and organic curves for the Floraprise dashboard hero and card headers.
class BotanicalHeroPainter extends CustomPainter {
  const BotanicalHeroPainter({
    this.primaryColor = const Color(0xFF1E5E3A),
    this.accentColor = const Color(0xFFD4A054),
    this.opacity = 0.18,
  });

  final Color primaryColor;
  final Color accentColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Organic background wave
    final wavePaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.fill;

    final wavePath = Path()
      ..moveTo(w * 0.6, 0)
      ..cubicTo(w * 0.75, h * 0.2, w * 0.65, h * 0.8, w, h * 0.6)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(wavePath, wavePaint);

    // Accent flowing wave
    final accentPaint = Paint()
      ..color = accentColor.withValues(alpha: opacity * 0.4)
      ..style = PaintingStyle.fill;

    final accentWave = Path()
      ..moveTo(w * 0.7, 0)
      ..cubicTo(w * 0.82, h * 0.35, w * 0.8, h * 0.9, w, h * 0.95)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(accentWave, accentPaint);

    // Draw stylized botanical leaf cluster in top-right
    final leafPaint = Paint()
      ..color = accentColor.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawLeaf(
      canvas,
      leafPaint,
      center: Offset(w * 0.92, h * 0.4),
      length: h * 0.45,
      angle: -math.pi / 4,
    );

    _drawLeaf(
      canvas,
      leafPaint,
      center: Offset(w * 0.96, h * 0.55),
      length: h * 0.35,
      angle: -math.pi / 6,
    );

    _drawLeaf(
      canvas,
      leafPaint,
      center: Offset(w * 0.88, h * 0.6),
      length: h * 0.3,
      angle: -math.pi / 2.5,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Paint paint, {
    required Offset center,
    required double length,
    required double angle,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(length * 0.3, -length * 0.25, length, 0);
    path.quadraticBezierTo(length * 0.3, length * 0.25, 0, 0);

    // Center stem
    path.moveTo(0, 0);
    path.lineTo(length * 0.85, 0);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BotanicalHeroPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.opacity != opacity;
}

/// Subtle watermark petal pattern for empty states or card backgrounds.
class BotanicalPetalPainter extends CustomPainter {
  const BotanicalPetalPainter({
    this.color = const Color(0xFF2E7D32),
    this.opacity = 0.08,
  });

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) * 0.75;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 6; i++) {
      final angle = i * (math.pi / 3);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(radius * 0.4, -radius * 0.4, radius, 0)
        ..quadraticBezierTo(radius * 0.4, radius * 0.4, 0, 0);
      canvas.drawPath(petal, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BotanicalPetalPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
