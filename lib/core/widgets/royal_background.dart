import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The signature backdrop: a midnight gradient overlaid with a subtle
/// Islamic geometric pattern of eight-pointed stars.
class RoyalBackground extends StatelessWidget {
  const RoyalBackground({super.key, required this.child, this.glow = true});

  final Widget child;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: GeometricPatternPainter(color: palette.pattern),
            ),
          ),
          if (glow)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.1),
                    radius: 1.1,
                    colors: [
                      palette.accent.withValues(alpha: 0.2),
                      palette.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Paints a tiling of eight-pointed stars (two overlapping squares) joined
/// by small diamonds, in faint gold lines.
class GeometricPatternPainter extends CustomPainter {
  const GeometricPatternPainter({
    this.tile = 64,
    this.color = const Color(0x14E9B44C),
  });

  final double tile;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final radius = tile * 0.34;
    final columns = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final center = Offset(col * tile, row * tile);
        canvas
          ..drawPath(_square(center, radius, 0), paint)
          ..drawPath(_square(center, radius, math.pi / 4), paint)
          ..drawCircle(center, radius * 0.38, paint);
        // Diamond linking neighbouring stars.
        canvas.drawPath(
          _square(
            center + Offset(tile / 2, tile / 2),
            tile * 0.16,
            math.pi / 4,
          ),
          paint,
        );
      }
    }
  }

  Path _square(Offset center, double radius, double rotation) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = rotation + math.pi / 4 + i * math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(GeometricPatternPainter oldDelegate) =>
      oldDelegate.tile != tile || oldDelegate.color != color;
}
