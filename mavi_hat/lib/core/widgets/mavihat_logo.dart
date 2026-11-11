import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Custom vector brand logo for MaviHat ("İstanbul Akıllı Ulaşım Cüzdanı").
///
/// Renders the Bosphorus suspension bridge silhouette, sea wave ribbons,
/// and contactless transit signal arcs inside a rounded Bosphorus emblem.
class MaviHatLogo extends StatelessWidget {
  const MaviHatLogo({
    super.key,
    this.size = 56,
    this.showBadge = false,
  });

  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.28;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF001E34),
                  Color(0xFF003B64),
                  Color(0xFF006767),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: const Color(0xFF8DD3D1).withValues(alpha: 0.45),
                width: size * 0.03,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.24),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: CustomPaint(
                painter: _MaviHatLogoPainter(),
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: -size * 0.06,
              bottom: -size * 0.06,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF006767),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.contactless_rounded,
                  color: const Color(0xFFA9EFED),
                  size: size * 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MaviHatLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Subtle upper glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.35),
        radius: 0.75,
        colors: <Color>[
          const Color(0xFFA9EFED).withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // Bosphorus Bridge Towers
    final bridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final leftTowerX = w * 0.28;
    final rightTowerX = w * 0.72;
    final towerTopY = h * 0.24;
    final deckY = h * 0.60;

    canvas.drawLine(
      Offset(leftTowerX, towerTopY),
      Offset(leftTowerX, deckY + h * 0.06),
      bridgePaint,
    );
    canvas.drawLine(
      Offset(rightTowerX, towerTopY),
      Offset(rightTowerX, deckY + h * 0.06),
      bridgePaint,
    );

    // Bridge Deck
    final deckPaint = Paint()
      ..color = const Color(0xFFA9EFED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.042
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.10, deckY),
      Offset(w * 0.90, deckY),
      deckPaint,
    );

    // Main Suspension Cable Catenary
    final cablePath = Path()
      ..moveTo(w * 0.10, deckY - h * 0.04)
      ..quadraticBezierTo(w * 0.19, h * 0.44, leftTowerX, towerTopY + h * 0.02)
      ..quadraticBezierTo(w * 0.50, h * 0.54, rightTowerX, towerTopY + h * 0.02)
      ..quadraticBezierTo(w * 0.81, h * 0.44, w * 0.90, deckY - h * 0.04);

    final cablePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032;
    canvas.drawPath(cablePath, cablePaint);

    // Bosphorus Sea Waves (2 layered curves at bottom)
    final wave1 = Path()
      ..moveTo(w * 0.12, h * 0.74)
      ..cubicTo(w * 0.32, h * 0.66, w * 0.46, h * 0.82, w * 0.66, h * 0.73)
      ..quadraticBezierTo(w * 0.79, h * 0.68, w * 0.88, h * 0.74);

    final wave2 = Path()
      ..moveTo(w * 0.18, h * 0.85)
      ..cubicTo(w * 0.38, h * 0.78, w * 0.54, h * 0.91, w * 0.82, h * 0.83);

    final wavePaint1 = Paint()
      ..color = const Color(0xFF8DD3D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.048
      ..strokeCap = StrokeCap.round;

    final wavePaint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.036
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(wave1, wavePaint1);
    canvas.drawPath(wave2, wavePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

