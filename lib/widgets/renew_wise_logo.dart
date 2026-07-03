import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/brand_theme.dart';

/// Official RenewWise logo — shield, brain, clock.
///
/// Communicates protection, memory, planning, and peace of mind.
/// Vector-drawn for crisp rendering at any size.
class RenewWiseLogo extends StatelessWidget {
  const RenewWiseLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.26);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: BrandTheme.colors.logoGradient,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(70),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(painter: const _RenewWiseLogoPainter()),
      ),
    );
  }
}

class _RenewWiseLogoPainter extends CustomPainter {
  const _RenewWiseLogoPainter();

  Path _shieldPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.84, h * 0.22)
      ..lineTo(w * 0.78, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.22, h * 0.58)
      ..lineTo(w * 0.16, h * 0.22)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shield = _shieldPath(w, h);

    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withAlpha(36), Colors.white.withAlpha(8)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withAlpha(220)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeJoin = StrokeJoin.round,
    );

    _drawBrain(canvas, w, h);
    _drawClock(canvas, w, h);
  }

  void _drawBrain(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;

    final cx = w * 0.5;
    final top = h * 0.24;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - w * 0.12, top), radius: w * 0.12),
      math.pi * 0.15,
      math.pi * 0.95,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + w * 0.12, top), radius: w * 0.12),
      math.pi * 0.9,
      math.pi * 0.95,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(cx, top - w * 0.02),
      Offset(cx, top + w * 0.14),
      paint,
    );
  }

  void _drawClock(Canvas canvas, double w, double h) {
    final cx = w * 0.5;
    final cy = h * 0.56;
    final r = w * 0.11;
    final ring = Paint()
      ..color = Colors.white.withAlpha(215)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022;

    canvas.drawCircle(Offset(cx, cy), r, ring);

    final hand = Paint()
      ..color = Colors.white.withAlpha(215)
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - r * 0.55),
      hand,
    );
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.42, cy - r * 0.35),
      hand,
    );
    canvas.drawCircle(Offset(cx, cy), w * 0.016, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
