import 'piece.dart';
import 'square.dart';

/// Special kinds of chess moves.
enum MoveKind {
  normal,
  doublePawnPush,
  enPassant,
  castleKingside,
  castleQueenside,
}

/// A move in the public API. Squares use 0..63 indexing (see [Square]).
class Move {
  const Move({
    required this.from,
    required this.to,
    required this.piece,
    this.captured,
    this.promotion,
    this.kind = MoveKind.normal,
  });

  final int from;
  final int to;

  /// The piece being moved (before any promotion).
  final Piece piece;

  /// The piece being captured, if any (including en passant captures).
  final Piece? captured;

  /// The piece type a pawn promotes to, if this is a promotion.
  final PieceType? promotion;

  final MoveKind kind;

  bool get isCapture => captured != null;

  bool get isPromotion => promotion != null;

  bool get isCastle =>
      kind == MoveKind.castleKingside || kind == MoveKind.castleQueenside;

  bool get isEnPassant => kind == MoveKind.enPassant;

  /// Long algebraic notation used by the UCI protocol, e.g. `e7e8q`.
  String get uci =>
      '${Square.name(from)}${Square.name(to)}${promotion?.letter ?? ''}';

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() => uci;
}
