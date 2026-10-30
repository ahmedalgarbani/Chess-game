import 'package:flutter/material.dart';

import '../../engine/chess_engine.dart';
import '../theme/board_theme.dart';

/// Paints a chess piece from hand-designed vector paths.
///
/// All shapes are authored in a 100 × 100 design space and scaled to the
/// target size, so pieces stay crisp at any resolution without image assets.
class PiecePainter extends CustomPainter {
  const PiecePainter({
    required this.piece,
    required this.style,
    this.shadow = true,
  });

  final Piece piece;
  final PieceStyle style;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas
      ..save()
      ..translate(
        (size.width - 100 * scale) / 2,
        (size.height - 100 * scale) / 2,
      )
      ..scale(scale);

    final white = piece.color == PieceColor.white;
    final fill = white ? style.whiteFill : style.blackFill;
    final stroke = white ? style.whiteStroke : style.blackStroke;
    final shape = _PieceShapes.forType(piece.type);

    if (shadow) {
      canvas.drawOval(
        const Rect.fromLTRB(20, 86, 80, 98),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    final body = shape.body;
    final bounds = body.getBounds();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: fill,
        ).createShader(bounds),
    );

    // A soft sheen on the left side gives the pieces some volume.
    canvas
      ..save()
      ..clipPath(body);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: white ? 0.45 : 0.18),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: white ? 0.10 : 0.25),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(bounds),
    );
    canvas.restore();

    final outline = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(body, outline);

    final details = shape.details;
    if (details != null) {
      canvas.drawPath(details, outline..strokeWidth = 2.6);
    }
    final dots = shape.dots;
    if (dots != null) {
      canvas.drawPath(
        dots,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(PiecePainter oldDelegate) =>
      oldDelegate.piece != piece ||
      oldDelegate.style != style ||
      oldDelegate.shadow != shadow;
}

/// A chess piece widget sized by its parent or by [size].
class PieceView extends StatelessWidget {
  const PieceView({
    super.key,
    required this.piece,
    required this.style,
    this.size,
    this.shadow = true,
  });

  final Piece piece;
  final PieceStyle style;
  final double? size;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: PiecePainter(piece: piece, style: style, shadow: shadow),
      ),
    );
  }
}

class _PieceShape {
  const _PieceShape({required this.body, this.details, this.dots});

  /// The filled silhouette (also outlined).
  final Path body;

  /// Interior lines drawn with the outline colour.
  final Path? details;

  /// Small filled marks such as eyes.
  final Path? dots;
}

abstract final class _PieceShapes {
  static _PieceShape forType(PieceType type) => switch (type) {
    PieceType.pawn => pawn,
    PieceType.knight => knight,
    PieceType.bishop => bishop,
    PieceType.rook => rook,
    PieceType.queen => queen,
    PieceType.king => king,
  };

  static RRect _r(double l, double t, double r, double b, double radius) =>
      RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));

  /// Plinth and base shared by every piece.
  static Path _base() => Path()
    ..addRRect(_r(27, 76, 73, 84, 3))
    ..addRRect(_r(21, 83, 79, 93, 4.5));

  static Path _union(List<Path> paths) {
    var result = paths.first;
    for (final path in paths.skip(1)) {
      result = Path.combine(PathOperation.union, result, path);
    }
    return result;
  }

  static final _PieceShape pawn = _PieceShape(
    body: _union([
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(50, 26), radius: 12)),
      Path()..addRRect(_r(37, 38, 63, 44.5, 3)),
      Path()
        ..moveTo(41, 44)
        ..cubicTo(41, 56, 34, 66, 30, 77)
        ..lineTo(70, 77)
        ..cubicTo(66, 66, 59, 56, 59, 44)
        ..close(),
      _base(),
    ]),
    details: Path()
      ..moveTo(28, 84)
      ..lineTo(72, 84),
  );

  static final _PieceShape rook = _PieceShape(
    body: _union([
      Path()
        ..moveTo(26, 16)
        ..lineTo(36, 16)
        ..lineTo(36, 23)
        ..lineTo(45, 23)
        ..lineTo(45, 16)
        ..lineTo(55, 16)
        ..lineTo(55, 23)
        ..lineTo(64, 23)
        ..lineTo(64, 16)
        ..lineTo(74, 16)
        ..lineTo(74, 33)
        ..lineTo(26, 33)
        ..close(),
      Path()..addRRect(_r(29, 32, 71, 38, 2)),
      Path()
        ..moveTo(34, 37)
        ..lineTo(66, 37)
        ..lineTo(69, 72)
        ..lineTo(31, 72)
        ..close(),
      Path()..addRRect(_r(27, 70, 73, 77, 2.5)),
      _base(),
    ]),
    details: Path()
      ..moveTo(30, 33)
      ..lineTo(70, 33)
      ..moveTo(32, 71)
      ..lineTo(68, 71)
      ..moveTo(28, 84)
      ..lineTo(72, 84),
  );

  static final _PieceShape bishop = _PieceShape(
    body: _union([
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(50, 12.5), radius: 5.5)),
      Path()
        ..moveTo(50, 18)
        ..cubicTo(62, 25, 68, 38, 64, 50)
        ..cubicTo(62, 56, 57, 60, 50, 60)
        ..cubicTo(43, 60, 38, 56, 36, 50)
        ..cubicTo(32, 38, 38, 25, 50, 18)
        ..close(),
      Path()..addRRect(_r(37, 58, 63, 64.5, 3)),
      Path()
        ..moveTo(42, 64)
        ..cubicTo(42, 70, 36, 73, 32, 77)
        ..lineTo(68, 77)
        ..cubicTo(64, 73, 58, 70, 58, 64)
        ..close(),
      _base(),
    ]),
    details: Path()
      ..moveTo(56, 29)
      ..lineTo(46, 43)
      ..moveTo(38, 61)
      ..lineTo(62, 61)
      ..moveTo(28, 84)
      ..lineTo(72, 84),
  );

  static final _PieceShape knight = _PieceShape(
    body: _union([
      Path()
        ..moveTo(69, 77)
        ..cubicTo(72, 62, 70, 44, 62, 33)
        ..cubicTo(59, 28, 56, 24, 53, 20)
        ..lineTo(51, 9)
        ..lineTo(45, 18)
        ..cubicTo(36, 21, 27, 29, 21, 41)
        ..cubicTo(18, 46, 19, 52, 25, 54)
        ..cubicTo(30, 55, 36, 52, 41, 48)
        ..cubicTo(44, 51, 43, 57, 38, 62)
        ..cubicTo(33, 67, 31, 72, 31, 77)
        ..close(),
      _base(),
    ]),
    details: Path()
      ..moveTo(60, 36)
      ..cubicTo(65, 47, 66, 60, 64, 72)
      ..moveTo(28, 84)
      ..lineTo(72, 84),
    dots: Path()
      ..addOval(Rect.fromCircle(center: const Offset(42, 31), radius: 3))
      ..addOval(Rect.fromCircle(center: const Offset(24.5, 47), radius: 1.8)),
  );

  static Path _queenCrown() => Path()
    ..moveTo(31, 61)
    ..lineTo(22, 30)
    ..lineTo(30, 45)
    ..lineTo(36, 22)
    ..lineTo(43, 42)
    ..lineTo(50, 18)
    ..lineTo(57, 42)
    ..lineTo(64, 22)
    ..lineTo(70, 45)
    ..lineTo(78, 30)
    ..lineTo(69, 61)
    ..close();

  static final _PieceShape queen = _PieceShape(
    body: _union([
      _queenCrown(),
      for (final c in const [
        Offset(22, 27),
        Offset(36, 19),
        Offset(50, 15),
        Offset(64, 19),
        Offset(78, 27),
      ])
        Path()..addOval(Rect.fromCircle(center: c, radius: 4.8)),
      Path()..addRRect(_r(30, 59, 70, 66, 3)),
      Path()
        ..moveTo(35, 65)
        ..cubicTo(35, 70, 31, 74, 29, 77)
        ..lineTo(71, 77)
        ..cubicTo(69, 74, 65, 70, 65, 65)
        ..close(),
      _base(),
    ]),
    details: Path()
      ..moveTo(32, 59)
      ..lineTo(68, 59)
      ..moveTo(28, 84)
      ..lineTo(72, 84),
  );

  static final _PieceShape king = _PieceShape(
    body: _union([
      Path()
        ..moveTo(46.5, 5)
        ..lineTo(53.5, 5)
        ..lineTo(53.5, 11)
        ..lineTo(60, 11)
        ..lineTo(60, 18)
        ..lineTo(53.5, 18)
        ..lineTo(53.5, 27)
        ..lineTo(46.5, 27)
        ..lineTo(46.5, 18)
        ..lineTo(40, 18)
        ..lineTo(40, 11)
        ..lineTo(46.5, 11)
        ..close(),
      Path()
        ..moveTo(31, 59)
        ..cubicTo(21, 47, 23, 31, 36, 29)
        ..cubicTo(43, 28, 48, 32, 50, 37)
        ..cubicTo(52, 32, 57, 28, 64, 29)
        ..cubicTo(77, 31, 79, 47, 69, 59)
        ..close(),
      Path()..addRRect(_r(30, 57, 70, 64, 3)),
      Path()
        ..moveTo(35, 63)
        ..cubicTo(35, 69, 31, 73, 29, 77)
        ..lineTo(71, 77)
        ..cubicTo(69, 73, 65, 69, 65, 63)
        ..close(),
      _base(),
    ]),
    details: Path()
      ..moveTo(50, 38)
      ..lineTo(50, 56)
      ..moveTo(32, 57)
      ..lineTo(68, 57)
      ..moveTo(28, 84)
      ..lineTo(72, 84),
  );
}
