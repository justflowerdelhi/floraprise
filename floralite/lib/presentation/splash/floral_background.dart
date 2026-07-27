import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloralBackground extends StatelessWidget {
  const FloralBackground({super.key});

  static const _topColor = Color(0xFF062F25);
  static const _middleColor = Color(0xFF0E4A37);
  static const _bottomColor = Color(0xFF0A382C);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_topColor, _middleColor, _bottomColor],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: const _FloralPatternOverlay(),
    );
  }
}

class _FloralPatternOverlay extends StatelessWidget {
  const _FloralPatternOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _FloralPatternPainter(),
    );
  }
}

class _FloralPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawRose(canvas, size, paint, 0.1, 0.15, 40);
    _drawRose(canvas, size, paint, 0.8, 0.2, 35);
    _drawRose(canvas, size, paint, 0.2, 0.7, 45);
    _drawRose(canvas, size, paint, 0.7, 0.8, 38);
    _drawLeaf(canvas, size, paint, 0.15, 0.4, 30);
    _drawLeaf(canvas, size, paint, 0.85, 0.5, 25);
    _drawStem(canvas, size, paint, 0.3, 0.3, 60);
    _drawStem(canvas, size, paint, 0.6, 0.6, 55);
    _drawBouquet(canvas, size, paint, 0.5, 0.85, 50);
  }

  void _drawRose(Canvas canvas, Size size, Paint paint, double x, double y, double scale) {
    final centerX = size.width * x;
    final centerY = size.height * y;
    final radius = scale;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final petalX = centerX + radius * 0.8 * math.cos(angle);
      final petalY = centerY + radius * 0.8 * math.sin(angle);
      canvas.drawCircle(Offset(petalX, petalY), radius * 0.4, paint);
    }
  }

  void _drawLeaf(Canvas canvas, Size size, Paint paint, double x, double y, double scale) {
    final startX = size.width * x;
    final startY = size.height * y;
    final path = Path();
    path.moveTo(startX, startY);
    path.quadraticBezierTo(
      startX + scale,
      startY - scale * 0.5,
      startX + scale * 1.5,
      startY,
    );
    path.quadraticBezierTo(
      startX + scale,
      startY + scale * 0.5,
      startX,
      startY,
    );
    canvas.drawPath(path, paint);
  }

  void _drawStem(Canvas canvas, Size size, Paint paint, double x, double y, double height) {
    final startX = size.width * x;
    final startY = size.height * y;
    final path = Path();
    path.moveTo(startX, startY);
    path.quadraticBezierTo(
      startX + 10,
      startY + height * 0.3,
      startX - 5,
      startY + height,
    );
    canvas.drawPath(path, paint);
  }

  void _drawBouquet(Canvas canvas, Size size, Paint paint, double x, double y, double scale) {
    final centerX = size.width * x;
    final centerY = size.height * y;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * math.pi / 180;
      final endX = centerX + scale * math.cos(angle);
      final endY = centerY + scale * math.sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
