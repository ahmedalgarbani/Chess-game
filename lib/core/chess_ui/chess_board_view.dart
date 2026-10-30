import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/chess_engine.dart';
import '../theme/app_colors.dart';
import '../theme/board_theme.dart';
import 'piece_painter.dart';

/// An arrow drawn over the board (hints, threats, predicted lines).
class BoardArrow {
  const BoardArrow({
    required this.from,
    required this.to,
    required this.color,
    this.label,
  });

  final int from;
  final int to;
  final Color color;

  /// Optional short label (e.g. a move number) drawn at the arrow head.
  final String? label;
}

enum SquareMarkKind { danger, star, goal, info }

/// A visual marker on a square (threatened piece, lesson star, …).
class SquareMark {
  const SquareMark(this.square, this.kind);

  final int square;
  final SquareMarkKind kind;
}

/// Interactive chess board with tap-to-move, drag-and-drop, move
/// animations and overlays. It is purely presentational: all rules live in
/// the caller, which reacts to [onSquareTap] and [onMove].
class ChessBoardView extends StatefulWidget {
  const ChessBoardView({
    super.key,
    required this.pieces,
    required this.boardTheme,
    required this.pieceStyle,
    this.flipped = false,
    this.selectedSquare,
    this.targetMoves = const [],
    this.lastMove,
    this.checkSquare,
    this.marks = const [],
    this.arrows = const [],
    this.movableColor,
    this.showCoordinates = true,
    this.showLegalMoves = true,
    this.moveCount = 0,
    this.onSquareTap,
    this.onDragStart,
    this.onMove,
  });

  /// The 64 squares, index 0 = a1.
  final List<Piece?> pieces;
  final BoardTheme boardTheme;
  final PieceStyle pieceStyle;

  /// When true, black is shown at the bottom.
  final bool flipped;
  final int? selectedSquare;

  /// Legal moves of the selected piece, shown as dots and rings.
  final List<Move> targetMoves;
  final Move? lastMove;
  final int? checkSquare;
  final List<SquareMark> marks;
  final List<BoardArrow> arrows;

  /// Which side's pieces may be dragged; null disables dragging.
  final PieceColor? movableColor;
  final bool showCoordinates;
  final bool showLegalMoves;

  /// Number of moves played; an increase by one animates [lastMove].
  final int moveCount;

  final ValueChanged<int>? onSquareTap;
  final ValueChanged<int>? onDragStart;
  final void Function(int from, int to)? onMove;

  @override
  State<ChessBoardView> createState() => _ChessBoardViewState();
}

class _ChessBoardViewState extends State<ChessBoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  Move? _animatedMove;
  Piece? _fadingPiece;
  int? _fadingSquare;

  int? _dragFrom;
  Offset? _dragPosition;
  (int, int)? _droppedMove;

  @override
  void didUpdateWidget(ChessBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final move = widget.lastMove;
    if (widget.moveCount == oldWidget.moveCount + 1 && move != null) {
      final dropped = _droppedMove;
      _droppedMove = null;
      if (dropped != null && dropped.$1 == move.from && dropped.$2 == move.to) {
        return;
      }
      final capturedSquare = move.isEnPassant
          ? Square.at(Square.file(move.to), Square.rank(move.from))
          : move.to;
      _animatedMove = move;
      _fadingSquare = move.isCapture ? capturedSquare : null;
      _fadingPiece = move.isCapture ? oldWidget.pieces[capturedSquare] : null;
      _animation.forward(from: 0);
    } else if (widget.moveCount != oldWidget.moveCount) {
      _animatedMove = null;
      _fadingPiece = null;
      _animation.value = 1;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  int _squareAt(Offset position, double squareSize) {
    final col = (position.dx / squareSize).floor().clamp(0, 7);
    final row = (position.dy / squareSize).floor().clamp(0, 7);
    final file = widget.flipped ? 7 - col : col;
    final rank = widget.flipped ? row : 7 - row;
    return Square.at(file, rank);
  }

  Offset _squareOrigin(int square, double squareSize) {
    final file = Square.file(square);
    final rank = Square.rank(square);
    final col = widget.flipped ? 7 - file : file;
    final row = widget.flipped ? rank : 7 - rank;
    return Offset(col * squareSize, row * squareSize);
  }

  (int, int)? _castlingRook(Move move) {
    return switch (move.kind) {
      MoveKind.castleKingside => (move.to + 1, move.to - 1),
      MoveKind.castleQueenside => (move.to - 2, move.to + 1),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final squareSize = constraints.maxWidth / 8;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => widget.onSquareTap?.call(
                _squareAt(details.localPosition, squareSize),
              ),
              onPanStart: (details) =>
                  _startDrag(details.localPosition, squareSize),
              onPanUpdate: (details) {
                if (_dragFrom != null) {
                  setState(() => _dragPosition = details.localPosition);
                }
              },
              onPanEnd: (_) => _endDrag(squareSize),
              onPanCancel: () => setState(() {
                _dragFrom = null;
                _dragPosition = null;
              }),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => _buildLayers(squareSize),
              ),
            );
          },
        ),
      ),
    );
  }

  void _startDrag(Offset position, double squareSize) {
    final square = _squareAt(position, squareSize);
    final piece = widget.pieces[square];
    if (piece == null || piece.color != widget.movableColor) return;
    setState(() {
      _dragFrom = square;
      _dragPosition = position;
    });
    widget.onDragStart?.call(square);
  }

  void _endDrag(double squareSize) {
    final from = _dragFrom;
    final position = _dragPosition;
    setState(() {
      _dragFrom = null;
      _dragPosition = null;
    });
    if (from == null || position == null) return;
    final to = _squareAt(position, squareSize);
    if (to == from) return;
    _droppedMove = (from, to);
    widget.onMove?.call(from, to);
  }

  Widget _buildLayers(double squareSize) {
    final progress = Curves.easeOutCubic.transform(_animation.value);
    final animating = _animation.isAnimating && _animatedMove != null;
    final move = _animatedMove;
    final rook = move == null ? null : _castlingRook(move);

    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _BoardPainter(
            theme: widget.boardTheme,
            flipped: widget.flipped,
            showCoordinates: widget.showCoordinates,
            selectedSquare: widget.selectedSquare,
            lastMove: widget.lastMove,
            checkSquare: widget.checkSquare,
            targetMoves: widget.showLegalMoves ? widget.targetMoves : const [],
            marks: widget.marks,
            hoverSquare: _dragPosition == null
                ? null
                : _squareAt(_dragPosition!, squareSize),
          ),
        ),
      ),
    ];

    if (animating && _fadingPiece != null && _fadingSquare != null) {
      final origin = _squareOrigin(_fadingSquare!, squareSize);
      children.add(
        Positioned(
          left: origin.dx,
          top: origin.dy,
          width: squareSize,
          height: squareSize,
          child: Opacity(
            opacity: 1 - progress,
            child: PieceView(piece: _fadingPiece!, style: widget.pieceStyle),
          ),
        ),
      );
    }

    for (var square = 0; square < 64; square++) {
      final piece = widget.pieces[square];
      if (piece == null || square == _dragFrom) continue;
      var origin = _squareOrigin(square, squareSize);
      if (animating) {
        if (square == move!.to) {
          origin = Offset.lerp(
            _squareOrigin(move.from, squareSize),
            origin,
            progress,
          )!;
        } else if (rook != null && square == rook.$2) {
          origin = Offset.lerp(
            _squareOrigin(rook.$1, squareSize),
            origin,
            progress,
          )!;
        }
      }
      children.add(
        Positioned(
          key: ValueKey('piece-$square'),
          left: origin.dx,
          top: origin.dy,
          width: squareSize,
          height: squareSize,
          child: PieceView(piece: piece, style: widget.pieceStyle),
        ),
      );
    }

    if (widget.arrows.isNotEmpty) {
      children.add(
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ArrowPainter(
                arrows: widget.arrows,
                flipped: widget.flipped,
              ),
            ),
          ),
        ),
      );
    }

    final dragFrom = _dragFrom;
    final dragPosition = _dragPosition;
    if (dragFrom != null && dragPosition != null) {
      final piece = widget.pieces[dragFrom];
      if (piece != null) {
        final size = squareSize * 1.35;
        children.add(
          Positioned(
            left: dragPosition.dx - size / 2,
            top: dragPosition.dy - size * 0.85,
            width: size,
            height: size,
            child: IgnorePointer(
              child: PieceView(piece: piece, style: widget.pieceStyle),
            ),
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.theme,
    required this.flipped,
    required this.showCoordinates,
    required this.selectedSquare,
    required this.lastMove,
    required this.checkSquare,
    required this.targetMoves,
    required this.marks,
    required this.hoverSquare,
  });

  final BoardTheme theme;
  final bool flipped;
  final bool showCoordinates;
  final int? selectedSquare;
  final Move? lastMove;
  final int? checkSquare;
  final List<Move> targetMoves;
  final List<SquareMark> marks;
  final int? hoverSquare;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 8;

    Rect rectOf(int square) {
      final file = Square.file(square);
      final rank = Square.rank(square);
      final col = flipped ? 7 - file : file;
      final row = flipped ? rank : 7 - rank;
      return Rect.fromLTWH(col * s, row * s, s, s);
    }

    final light = Paint()..color = theme.light;
    final dark = Paint()..color = theme.dark;
    for (var square = 0; square < 64; square++) {
      canvas.drawRect(rectOf(square), Square.isLight(square) ? light : dark);
    }
    // Gentle top-left lighting across the whole board.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF), Color(0x14000000)],
        ).createShader(Offset.zero & size),
    );

    final move = lastMove;
    if (move != null) {
      final paint = Paint()..color = const Color(0x70F7D560);
      canvas
        ..drawRect(rectOf(move.from), paint)
        ..drawRect(rectOf(move.to), paint);
    }

    if (selectedSquare != null) {
      canvas.drawRect(
        rectOf(selectedSquare!),
        Paint()..color = AppColors.gold.withValues(alpha: 0.65),
      );
    }

    if (hoverSquare != null) {
      canvas.drawRect(
        rectOf(hoverSquare!).deflate(s * 0.03),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.06,
      );
    }

    for (final mark in marks) {
      _paintMark(canvas, rectOf(mark.square), mark.kind, s);
    }

    if (checkSquare != null) {
      final rect = rectOf(checkSquare!);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFF2E4D).withValues(alpha: 0.95),
              const Color(0xFFFF2E4D).withValues(alpha: 0.35),
              const Color(0x00FF2E4D),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );
    }

    final dotPaint = Paint()..color = const Color(0x40101010);
    final ringPaint = Paint()
      ..color = const Color(0x45101010)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08;
    for (final target in targetMoves) {
      final rect = rectOf(target.to);
      if (target.isCapture) {
        canvas.drawCircle(rect.center, s * 0.44, ringPaint);
      } else {
        canvas.drawCircle(rect.center, s * 0.16, dotPaint);
      }
    }

    if (showCoordinates) _paintCoordinates(canvas, s, rectOf);
  }

  void _paintMark(Canvas canvas, Rect rect, SquareMarkKind kind, double s) {
    switch (kind) {
      case SquareMarkKind.danger:
        canvas
          ..drawRect(rect, Paint()..color = const Color(0x40FF3B5C))
          ..drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(s * 0.05),
              Radius.circular(s * 0.12),
            ),
            Paint()
              ..color = const Color(0xDDFF3B5C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.06,
          );
      case SquareMarkKind.goal:
        canvas.drawRect(rect, Paint()..color = const Color(0x552EC4A5));
      case SquareMarkKind.info:
        canvas.drawRect(rect, Paint()..color = const Color(0x556C9BFF));
      case SquareMarkKind.star:
        final center = rect.center;
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final radius = i.isEven ? s * 0.34 : s * 0.15;
          final angle = -math.pi / 2 + i * math.pi / 5;
          final point =
              center + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas
          ..drawPath(
            path,
            Paint()
              ..color = const Color(0x66000000)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          )
          ..drawPath(
            path,
            Paint()..shader = AppColors.goldGradient.createShader(rect),
          )
          ..drawPath(
            path,
            Paint()
              ..color = AppColors.goldDeep
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.025,
          );
    }
  }

  void _paintCoordinates(
    Canvas canvas,
    double s,
    Rect Function(int square) rectOf,
  ) {
    final fontSize = s * 0.2;
    for (var i = 0; i < 8; i++) {
      // Files along the bottom row, ranks along the left column.
      final fileSquare = Square.at(i, flipped ? 7 : 0);
      final rankSquare = Square.at(flipped ? 7 : 0, i);
      _paintLabel(
        canvas,
        'abcdefgh'[i],
        rectOf(fileSquare),
        Square.isLight(fileSquare),
        fontSize,
        Alignment.bottomRight,
      );
      _paintLabel(
        canvas,
        '${i + 1}',
        rectOf(rankSquare),
        Square.isLight(rankSquare),
        fontSize,
        Alignment.topLeft,
      );
    }
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Rect rect,
    bool onLight,
    double fontSize,
    Alignment alignment,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: onLight ? theme.coordinateLight : theme.coordinateDark,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final padding = rect.width * 0.06;
    final dx = alignment.x > 0
        ? rect.right - painter.width - padding
        : rect.left + padding;
    final dy = alignment.y > 0
        ? rect.bottom - painter.height - padding * 0.4
        : rect.top + padding * 0.4;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.theme != theme ||
      old.flipped != flipped ||
      old.showCoordinates != showCoordinates ||
      old.selectedSquare != selectedSquare ||
      old.lastMove != lastMove ||
      old.checkSquare != checkSquare ||
      old.targetMoves != targetMoves ||
      old.marks != marks ||
      old.hoverSquare != hoverSquare;
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.arrows, required this.flipped});

  final List<BoardArrow> arrows;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 8;
    Offset centerOf(int square) {
      final file = Square.file(square);
      final rank = Square.rank(square);
      final col = flipped ? 7 - file : file;
      final row = flipped ? rank : 7 - rank;
      return Offset((col + 0.5) * s, (row + 0.5) * s);
    }

    for (final arrow in arrows) {
      final start = centerOf(arrow.from);
      final end = centerOf(arrow.to);
      final delta = end - start;
      final length = delta.distance;
      if (length == 0) continue;
      final direction = delta / length;
      final normal = Offset(-direction.dy, direction.dx);
      final headLength = s * 0.42;
      final shaftWidth = s * 0.17;
      final headWidth = s * 0.44;
      final shaftEnd = end - direction * headLength;
      final tail = start + direction * s * 0.22;

      final path = Path()
        ..moveTo(
          tail.dx + normal.dx * shaftWidth / 2,
          tail.dy + normal.dy * shaftWidth / 2,
        )
        ..lineTo(
          shaftEnd.dx + normal.dx * shaftWidth / 2,
          shaftEnd.dy + normal.dy * shaftWidth / 2,
        )
        ..lineTo(
          shaftEnd.dx + normal.dx * headWidth / 2,
          shaftEnd.dy + normal.dy * headWidth / 2,
        )
        ..lineTo(end.dx, end.dy)
        ..lineTo(
          shaftEnd.dx - normal.dx * headWidth / 2,
          shaftEnd.dy - normal.dy * headWidth / 2,
        )
        ..lineTo(
          shaftEnd.dx - normal.dx * shaftWidth / 2,
          shaftEnd.dy - normal.dy * shaftWidth / 2,
        )
        ..lineTo(
          tail.dx - normal.dx * shaftWidth / 2,
          tail.dy - normal.dy * shaftWidth / 2,
        )
        ..close();

      canvas
        ..drawPath(
          path,
          Paint()
            ..color = const Color(0x55000000)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        )
        ..drawPath(path, Paint()..color = arrow.color.withValues(alpha: 0.85));

      final label = arrow.label;
      if (label != null) {
        final badgeCenter = tail;
        canvas
          ..drawCircle(badgeCenter, s * 0.2, Paint()..color = arrow.color)
          ..drawCircle(
            badgeCenter,
            s * 0.2,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.03,
          );
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.white,
              fontSize: s * 0.22,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          badgeCenter - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.arrows != arrows || old.flipped != flipped;
}
