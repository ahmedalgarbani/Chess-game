/// The two sides of a chess game.
enum PieceColor {
  white,
  black;

  PieceColor get opposite => this == white ? black : white;

  /// +1 for white and -1 for black, matching the sign convention of the
  /// internal board representation.
  int get sign => this == white ? 1 : -1;

  static PieceColor fromSign(int sign) => sign > 0 ? white : black;
}

/// The six kinds of chess pieces.
enum PieceType {
  pawn(1, 'p', 1),
  knight(2, 'n', 3),
  bishop(3, 'b', 3),
  rook(4, 'r', 5),
  queen(5, 'q', 9),
  king(6, 'k', 0);

  const PieceType(this.code, this.letter, this.value);

  /// Internal code used by the board representation (1..6).
  final int code;

  /// Lower-case letter used by FEN and UCI notation.
  final String letter;

  /// Conventional material value in pawns. The king has no material value.
  final int value;

  /// The upper-case letter used by SAN notation (empty for pawns).
  String get sanLetter => this == pawn ? '' : letter.toUpperCase();

  static PieceType fromCode(int code) => values[code - 1];

  static PieceType? fromLetter(String letter) {
    final lower = letter.toLowerCase();
    for (final type in values) {
      if (type.letter == lower) return type;
    }
    return null;
  }
}

/// An immutable chess piece: a [type] owned by a [color].
class Piece {
  const Piece(this.color, this.type);

  final PieceColor color;
  final PieceType type;

  static const whitePawn = Piece(PieceColor.white, PieceType.pawn);
  static const whiteKnight = Piece(PieceColor.white, PieceType.knight);
  static const whiteBishop = Piece(PieceColor.white, PieceType.bishop);
  static const whiteRook = Piece(PieceColor.white, PieceType.rook);
  static const whiteQueen = Piece(PieceColor.white, PieceType.queen);
  static const whiteKing = Piece(PieceColor.white, PieceType.king);
  static const blackPawn = Piece(PieceColor.black, PieceType.pawn);
  static const blackKnight = Piece(PieceColor.black, PieceType.knight);
  static const blackBishop = Piece(PieceColor.black, PieceType.bishop);
  static const blackRook = Piece(PieceColor.black, PieceType.rook);
  static const blackQueen = Piece(PieceColor.black, PieceType.queen);
  static const blackKing = Piece(PieceColor.black, PieceType.king);

  static const List<Piece> _white = [
    whitePawn,
    whiteKnight,
    whiteBishop,
    whiteRook,
    whiteQueen,
    whiteKing,
  ];
  static const List<Piece> _black = [
    blackPawn,
    blackKnight,
    blackBishop,
    blackRook,
    blackQueen,
    blackKing,
  ];

  /// Returns the shared instance for a signed internal [code], or null for 0.
  static Piece? fromCode(int code) {
    if (code == 0) return null;
    return code > 0 ? _white[code - 1] : _black[-code - 1];
  }

  /// Signed internal code: positive for white, negative for black.
  int get code => type.code * color.sign;

  /// FEN character: upper case for white, lower case for black.
  String get fenChar =>
      color == PieceColor.white ? type.letter.toUpperCase() : type.letter;

  @override
  bool operator ==(Object other) =>
      other is Piece && other.color == color && other.type == type;

  @override
  int get hashCode => Object.hash(color, type);

  @override
  String toString() => fenChar;
}
