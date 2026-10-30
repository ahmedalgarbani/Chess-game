import 'dart:math';
import 'dart:typed_data';

import 'move.dart';
import 'piece.dart';
import 'square.dart';

/// The standard starting position.
const String startingFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

/// Bit layout of the compact integer move encoding used by [Board]:
///
/// * bits 0..6   origin square (0x88 index)
/// * bits 7..13  destination square (0x88 index)
/// * bits 14..16 promotion piece code (0 when not a promotion)
/// * bits 17..20 flags ([capture], [enPassant], [castle], [doublePush])
abstract final class MoveBits {
  static const int capture = 1 << 17;
  static const int enPassant = 1 << 18;
  static const int castle = 1 << 19;
  static const int doublePush = 1 << 20;

  static int encode(int from, int to, [int promotion = 0, int flags = 0]) =>
      from | (to << 7) | (promotion << 14) | flags;

  static int from(int move) => move & 0x7F;

  static int to(int move) => (move >> 7) & 0x7F;

  static int promotion(int move) => (move >> 14) & 7;

  static bool isCapture(int move) => (move & capture) != 0;

  static bool isQuiet(int move) =>
      (move & capture) == 0 && promotion(move) == 0;
}

/// Mutable chess position using a 0x88 mailbox with make/unmake support.
///
/// Pieces are stored as signed codes: 1..6 for white (pawn..king) and
/// -1..-6 for black. The side to move is +1 (white) or -1 (black).
/// This class is optimised for search; the friendlier API lives in
/// `ChessGame`.
class Board {
  Board.empty();

  factory Board.fromFen(String fen) => Board.empty()..loadFen(fen);

  static const int castleWhiteKing = 1;
  static const int castleWhiteQueen = 2;
  static const int castleBlackKing = 4;
  static const int castleBlackQueen = 8;

  static const List<int> knightOffsets = [33, 31, 18, 14, -14, -18, -31, -33];
  static const List<int> kingOffsets = [17, 16, 15, 1, -1, -15, -16, -17];
  static const List<int> diagonalOffsets = [17, 15, -15, -17];
  static const List<int> orthogonalOffsets = [16, 1, -1, -16];

  /// Material values in centipawns indexed by piece code (index 0 unused).
  static const List<int> pieceValues = [0, 100, 320, 330, 500, 900, 20000];

  final Int8List squares = Int8List(128);
  int turn = 1;
  int castling = 0;
  int epSquare = -1;
  int halfmoveClock = 0;
  int fullmoveNumber = 1;
  int whiteKing = -1;
  int blackKing = -1;
  int hashLo = 0;
  int hashHi = 0;

  int _ply = 0;
  int _capacity = 0;
  late Int32List _undoMove;
  late Int32List _undoCaptured;
  late Int32List _undoCastling;
  late Int32List _undoEp;
  late Int32List _undoHalfmove;
  late Uint32List _undoHashLo;
  late Uint32List _undoHashHi;

  /// Number of moves made since the position was loaded.
  int get ply => _ply;

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  /// Loads a position from Forsyth–Edwards Notation.
  ///
  /// Throws a [FormatException] when the FEN is malformed. Missing clocks
  /// default to `0 1`. Castling rights that are impossible for the given
  /// piece placement are dropped.
  void loadFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) throw FormatException('Invalid FEN', fen);

    squares.fillRange(0, 128, 0);
    whiteKing = -1;
    blackKing = -1;

    final rows = parts[0].split('/');
    if (rows.length != 8) throw FormatException('Invalid FEN rows', fen);
    for (var row = 0; row < 8; row++) {
      final rank = 7 - row;
      var file = 0;
      for (final char in rows[row].split('')) {
        final digit = int.tryParse(char);
        if (digit != null) {
          file += digit;
          continue;
        }
        final type = PieceType.fromLetter(char);
        if (type == null || file > 7) {
          throw FormatException('Invalid FEN piece', fen);
        }
        final isWhite = char.toUpperCase() == char;
        final code = isWhite ? type.code : -type.code;
        final sq = rank * 16 + file;
        squares[sq] = code;
        if (code == 6) whiteKing = sq;
        if (code == -6) blackKing = sq;
        file++;
      }
      if (file != 8) throw FormatException('Invalid FEN row length', fen);
    }

    turn = switch (parts[1]) {
      'w' => 1,
      'b' => -1,
      _ => throw FormatException('Invalid side to move', fen),
    };

    castling = 0;
    final castlingField = parts.length > 2 ? parts[2] : '-';
    if (castlingField.contains('K') && whiteKing == 4 && squares[7] == 4) {
      castling |= castleWhiteKing;
    }
    if (castlingField.contains('Q') && whiteKing == 4 && squares[0] == 4) {
      castling |= castleWhiteQueen;
    }
    if (castlingField.contains('k') && blackKing == 116 && squares[119] == -4) {
      castling |= castleBlackKing;
    }
    if (castlingField.contains('q') && blackKing == 116 && squares[112] == -4) {
      castling |= castleBlackQueen;
    }

    epSquare = -1;
    final epField = parts.length > 3 ? parts[3] : '-';
    if (epField != '-') {
      final ep = Square.to0x88(Square.parse(epField));
      if (_canCaptureEnPassantOn(ep)) epSquare = ep;
    }

    halfmoveClock = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    fullmoveNumber = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    if (fullmoveNumber < 1) fullmoveNumber = 1;

    _ply = 0;
    _ensureCapacity(256);
    _recomputeHash();
  }

  /// Serialises the position to Forsyth–Edwards Notation.
  String toFen() {
    final buffer = StringBuffer();
    for (var rank = 7; rank >= 0; rank--) {
      var empty = 0;
      for (var file = 0; file < 8; file++) {
        final piece = Piece.fromCode(squares[rank * 16 + file]);
        if (piece == null) {
          empty++;
          continue;
        }
        if (empty > 0) {
          buffer.write(empty);
          empty = 0;
        }
        buffer.write(piece.fenChar);
      }
      if (empty > 0) buffer.write(empty);
      if (rank > 0) buffer.write('/');
    }
    buffer
      ..write(turn == 1 ? ' w ' : ' b ')
      ..write(_castlingString())
      ..write(' ')
      ..write(epSquare == -1 ? '-' : Square.name(Square.from0x88(epSquare)))
      ..write(' $halfmoveClock $fullmoveNumber');
    return buffer.toString();
  }

  /// The first four FEN fields, which identify a position for the purpose of
  /// repetition detection.
  String positionKey() {
    final fen = toFen();
    final parts = fen.split(' ');
    return parts.take(4).join(' ');
  }

  String _castlingString() {
    if (castling == 0) return '-';
    return [
      if (castling & castleWhiteKing != 0) 'K',
      if (castling & castleWhiteQueen != 0) 'Q',
      if (castling & castleBlackKing != 0) 'k',
      if (castling & castleBlackQueen != 0) 'q',
    ].join();
  }

  /// Sets the side to move without making a move. Used by free-play lessons.
  void setTurn(int side) {
    if (side == turn) return;
    if (epSquare != -1) _xorEp(epSquare);
    epSquare = -1;
    turn = side;
    _xorSide();
  }

  // ---------------------------------------------------------------------------
  // Hashing (two independent 32-bit Zobrist keys, safe on every platform)
  // ---------------------------------------------------------------------------

  static final _Zobrist _zobrist = _Zobrist();

  void _recomputeHash() {
    hashLo = 0;
    hashHi = 0;
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final piece = squares[sq];
      if (piece != 0) _xorPiece(piece, sq);
    }
    hashLo ^= _zobrist.castlingLo[castling];
    hashHi ^= _zobrist.castlingHi[castling];
    if (epSquare != -1) _xorEp(epSquare);
    if (turn == -1) _xorSide();
  }

  void _xorPiece(int piece, int sq) {
    final index = (piece + 6) * 128 + sq;
    hashLo ^= _zobrist.pieceLo[index];
    hashHi ^= _zobrist.pieceHi[index];
  }

  void _xorEp(int sq) {
    hashLo ^= _zobrist.epLo[sq & 7];
    hashHi ^= _zobrist.epHi[sq & 7];
  }

  void _xorSide() {
    hashLo ^= _zobrist.sideLo;
    hashHi ^= _zobrist.sideHi;
  }

  // ---------------------------------------------------------------------------
  // Attacks
  // ---------------------------------------------------------------------------

  /// Whether square [sq] (0x88) is attacked by any piece of side [by].
  bool isAttacked(int sq, int by) =>
      leastValuableAttacker(sq, by, stopAtFirst: true) != 0;

  /// Returns the code magnitude (1..6) of the least valuable piece of side
  /// [by] attacking [sq], or 0 if the square is not attacked.
  ///
  /// When [stopAtFirst] is true the first attacker found is returned, which
  /// is cheaper and sufficient for a yes/no answer.
  int leastValuableAttacker(int sq, int by, {bool stopAtFirst = false}) {
    final s = squares;
    // Pawns attack diagonally forward.
    if (by == 1) {
      if (_holds(sq - 15, 1) || _holds(sq - 17, 1)) return 1;
    } else {
      if (_holds(sq + 15, -1) || _holds(sq + 17, -1)) return 1;
    }
    final knight = 2 * by;
    for (final d in knightOffsets) {
      if (_holds(sq + d, knight)) return 2;
    }

    var best = 0;
    final bishop = 3 * by;
    final rook = 4 * by;
    final queen = 5 * by;
    for (final d in diagonalOffsets) {
      var t = sq + d;
      while ((t & 0x88) == 0) {
        final p = s[t];
        if (p != 0) {
          if (p == bishop) return 3;
          if (p == queen) {
            if (stopAtFirst) return 5;
            best = 5;
          }
          break;
        }
        t += d;
      }
    }
    for (final d in orthogonalOffsets) {
      var t = sq + d;
      while ((t & 0x88) == 0) {
        final p = s[t];
        if (p != 0) {
          if (p == rook) return 4;
          if (p == queen) {
            if (stopAtFirst) return 5;
            best = 5;
          }
          break;
        }
        t += d;
      }
    }
    if (best != 0) return best;

    final king = 6 * by;
    for (final d in kingOffsets) {
      if (_holds(sq + d, king)) return 6;
    }
    return 0;
  }

  bool _holds(int sq, int piece) => (sq & 0x88) == 0 && squares[sq] == piece;

  /// Whether the king of [side] is currently attacked. A missing king (as in
  /// some lesson positions) is never considered attacked.
  bool isKingAttacked(int side) {
    final king = side == 1 ? whiteKing : blackKing;
    return king >= 0 && isAttacked(king, -side);
  }

  /// Whether the side to move is in check.
  bool get inCheck => isKingAttacked(turn);

  bool _canCaptureEnPassantOn(int ep) {
    // The pawn that just double-pushed sits one rank "behind" the ep square
    // from the point of view of the side to move.
    final pawnSquare = ep - 16 * turn;
    if ((pawnSquare & 0x88) != 0 || squares[pawnSquare] != -turn) return false;
    final capturer = turn; // a pawn of the side to move
    return _holds(pawnSquare - 1, capturer) || _holds(pawnSquare + 1, capturer);
  }

  // ---------------------------------------------------------------------------
  // Move generation
  // ---------------------------------------------------------------------------

  /// Writes pseudo-legal moves for the side to move into [out] starting at
  /// [start] and returns the index after the last move written.
  ///
  /// With [tacticalOnly] only captures and queen promotions are generated,
  /// which is what quiescence search needs.
  int generatePseudoMoves(
    Int32List out,
    int start, {
    bool tacticalOnly = false,
  }) {
    var n = start;
    final us = turn;
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final p = squares[sq];
      if (p == 0 || (p > 0) != (us > 0)) continue;
      switch (p.abs()) {
        case 1:
          n = _generatePawnMoves(out, n, sq, tacticalOnly);
        case 2:
          n = _generateLeaperMoves(out, n, sq, knightOffsets, tacticalOnly);
        case 3:
          n = _generateSliderMoves(out, n, sq, diagonalOffsets, tacticalOnly);
        case 4:
          n = _generateSliderMoves(out, n, sq, orthogonalOffsets, tacticalOnly);
        case 5:
          n = _generateSliderMoves(out, n, sq, diagonalOffsets, tacticalOnly);
          n = _generateSliderMoves(out, n, sq, orthogonalOffsets, tacticalOnly);
        case 6:
          n = _generateLeaperMoves(out, n, sq, kingOffsets, tacticalOnly);
          if (!tacticalOnly) n = _generateCastlingMoves(out, n);
      }
    }
    return n;
  }

  /// Writes fully legal moves for the side to move into [out] starting at
  /// [start] and returns the index after the last move written.
  int generateLegalMoves(Int32List out, int start) {
    final end = generatePseudoMoves(out, start);
    var n = start;
    for (var i = start; i < end; i++) {
      final move = out[i];
      makeMove(move);
      final legal = !isKingAttacked(-turn);
      unmakeMove();
      if (legal) out[n++] = move;
    }
    return n;
  }

  /// Convenience wrapper returning the legal moves as a list.
  List<int> legalMoves() {
    final buffer = Int32List(256);
    final count = generateLegalMoves(buffer, 0);
    return List<int>.generate(count, (i) => buffer[i], growable: false);
  }

  /// Whether the side to move has at least one legal move.
  bool hasLegalMove() {
    final buffer = Int32List(256);
    final end = generatePseudoMoves(buffer, 0);
    for (var i = 0; i < end; i++) {
      makeMove(buffer[i]);
      final legal = !isKingAttacked(-turn);
      unmakeMove();
      if (legal) return true;
    }
    return false;
  }

  int _generatePawnMoves(Int32List out, int start, int sq, bool tacticalOnly) {
    var n = start;
    final us = turn;
    final forward = 16 * us;
    final startRank = us == 1 ? 1 : 6;
    final promotionRank = us == 1 ? 7 : 0;

    final one = sq + forward;
    if ((one & 0x88) == 0 && squares[one] == 0) {
      if ((one >> 4) == promotionRank) {
        n = _addPromotions(out, n, sq, one, 0, queenOnly: tacticalOnly);
      } else if (!tacticalOnly) {
        out[n++] = MoveBits.encode(sq, one);
        final two = one + forward;
        if ((sq >> 4) == startRank && squares[two] == 0) {
          out[n++] = MoveBits.encode(sq, two, 0, MoveBits.doublePush);
        }
      }
    }

    for (final d in us == 1 ? const [15, 17] : const [-15, -17]) {
      final target = sq + d;
      if ((target & 0x88) != 0) continue;
      final victim = squares[target];
      if (victim != 0 && (victim > 0) != (us > 0)) {
        if ((target >> 4) == promotionRank) {
          n = _addPromotions(
            out,
            n,
            sq,
            target,
            MoveBits.capture,
            queenOnly: tacticalOnly,
          );
        } else {
          out[n++] = MoveBits.encode(sq, target, 0, MoveBits.capture);
        }
      } else if (target == epSquare) {
        out[n++] = MoveBits.encode(
          sq,
          target,
          0,
          MoveBits.capture | MoveBits.enPassant,
        );
      }
    }
    return n;
  }

  int _addPromotions(
    Int32List out,
    int start,
    int from,
    int to,
    int flags, {
    required bool queenOnly,
  }) {
    var n = start;
    out[n++] = MoveBits.encode(from, to, 5, flags);
    if (!queenOnly) {
      out[n++] = MoveBits.encode(from, to, 4, flags);
      out[n++] = MoveBits.encode(from, to, 3, flags);
      out[n++] = MoveBits.encode(from, to, 2, flags);
    }
    return n;
  }

  int _generateLeaperMoves(
    Int32List out,
    int start,
    int sq,
    List<int> offsets,
    bool tacticalOnly,
  ) {
    var n = start;
    final us = turn;
    for (final d in offsets) {
      final target = sq + d;
      if ((target & 0x88) != 0) continue;
      final victim = squares[target];
      if (victim == 0) {
        if (!tacticalOnly) out[n++] = MoveBits.encode(sq, target);
      } else if ((victim > 0) != (us > 0)) {
        out[n++] = MoveBits.encode(sq, target, 0, MoveBits.capture);
      }
    }
    return n;
  }

  int _generateSliderMoves(
    Int32List out,
    int start,
    int sq,
    List<int> offsets,
    bool tacticalOnly,
  ) {
    var n = start;
    final us = turn;
    for (final d in offsets) {
      var target = sq + d;
      while ((target & 0x88) == 0) {
        final victim = squares[target];
        if (victim == 0) {
          if (!tacticalOnly) out[n++] = MoveBits.encode(sq, target);
        } else {
          if ((victim > 0) != (us > 0)) {
            out[n++] = MoveBits.encode(sq, target, 0, MoveBits.capture);
          }
          break;
        }
        target += d;
      }
    }
    return n;
  }

  int _generateCastlingMoves(Int32List out, int start) {
    var n = start;
    if (turn == 1) {
      if (whiteKing != 4) return n;
      if (castling & castleWhiteKing != 0 &&
          squares[5] == 0 &&
          squares[6] == 0 &&
          squares[7] == 4 &&
          !isAttacked(4, -1) &&
          !isAttacked(5, -1) &&
          !isAttacked(6, -1)) {
        out[n++] = MoveBits.encode(4, 6, 0, MoveBits.castle);
      }
      if (castling & castleWhiteQueen != 0 &&
          squares[3] == 0 &&
          squares[2] == 0 &&
          squares[1] == 0 &&
          squares[0] == 4 &&
          !isAttacked(4, -1) &&
          !isAttacked(3, -1) &&
          !isAttacked(2, -1)) {
        out[n++] = MoveBits.encode(4, 2, 0, MoveBits.castle);
      }
    } else {
      if (blackKing != 116) return n;
      if (castling & castleBlackKing != 0 &&
          squares[117] == 0 &&
          squares[118] == 0 &&
          squares[119] == -4 &&
          !isAttacked(116, 1) &&
          !isAttacked(117, 1) &&
          !isAttacked(118, 1)) {
        out[n++] = MoveBits.encode(116, 118, 0, MoveBits.castle);
      }
      if (castling & castleBlackQueen != 0 &&
          squares[115] == 0 &&
          squares[114] == 0 &&
          squares[113] == 0 &&
          squares[112] == -4 &&
          !isAttacked(116, 1) &&
          !isAttacked(115, 1) &&
          !isAttacked(114, 1)) {
        out[n++] = MoveBits.encode(116, 114, 0, MoveBits.castle);
      }
    }
    return n;
  }

  // ---------------------------------------------------------------------------
  // Make / unmake
  // ---------------------------------------------------------------------------

  /// Castling-rights mask applied for every move touching a square.
  static final Int8List _castleMask = () {
    final mask = Int8List(128)..fillRange(0, 128, 15);
    mask[4] = 15 & ~(castleWhiteKing | castleWhiteQueen);
    mask[7] = 15 & ~castleWhiteKing;
    mask[0] = 15 & ~castleWhiteQueen;
    mask[116] = 15 & ~(castleBlackKing | castleBlackQueen);
    mask[119] = 15 & ~castleBlackKing;
    mask[112] = 15 & ~castleBlackQueen;
    return mask;
  }();

  void _ensureCapacity(int needed) {
    if (needed <= _capacity) return;
    var capacity = _capacity == 0 ? 256 : _capacity;
    while (capacity < needed) {
      capacity *= 2;
    }
    Int32List grow32(Int32List? old) {
      final list = Int32List(capacity);
      if (old != null) list.setRange(0, _ply, old);
      return list;
    }

    Uint32List growU32(Uint32List? old) {
      final list = Uint32List(capacity);
      if (old != null) list.setRange(0, _ply, old);
      return list;
    }

    final hadData = _capacity > 0;
    _undoMove = grow32(hadData ? _undoMove : null);
    _undoCaptured = grow32(hadData ? _undoCaptured : null);
    _undoCastling = grow32(hadData ? _undoCastling : null);
    _undoEp = grow32(hadData ? _undoEp : null);
    _undoHalfmove = grow32(hadData ? _undoHalfmove : null);
    _undoHashLo = growU32(hadData ? _undoHashLo : null);
    _undoHashHi = growU32(hadData ? _undoHashHi : null);
    _capacity = capacity;
  }

  void _pushUndo(int move, int captured) {
    if (_ply >= _capacity) _ensureCapacity(_ply + 1);
    final i = _ply++;
    _undoMove[i] = move;
    _undoCaptured[i] = captured;
    _undoCastling[i] = castling;
    _undoEp[i] = epSquare;
    _undoHalfmove[i] = halfmoveClock;
    _undoHashLo[i] = hashLo;
    _undoHashHi[i] = hashHi;
  }

  /// Plays an encoded [move]. The move must be pseudo-legal for the side to
  /// move; legality with respect to check is the caller's responsibility.
  void makeMove(int move) {
    final from = move & 0x7F;
    final to = (move >> 7) & 0x7F;
    final promotion = (move >> 14) & 7;
    final us = turn;
    final piece = squares[from];

    var capturedSquare = to;
    if ((move & MoveBits.enPassant) != 0) capturedSquare = to - 16 * us;
    final captured = squares[capturedSquare];

    _pushUndo(move, captured);

    if (captured != 0) {
      squares[capturedSquare] = 0;
      _xorPiece(captured, capturedSquare);
    }

    squares[from] = 0;
    _xorPiece(piece, from);
    final placed = promotion != 0 ? promotion * us : piece;
    squares[to] = placed;
    _xorPiece(placed, to);

    if ((move & MoveBits.castle) != 0) {
      final (rookFrom, rookTo) = _castlingRookSquares(to);
      final rook = squares[rookFrom];
      squares[rookFrom] = 0;
      _xorPiece(rook, rookFrom);
      squares[rookTo] = rook;
      _xorPiece(rook, rookTo);
    }

    if (piece == 6) {
      whiteKing = to;
    } else if (piece == -6) {
      blackKing = to;
    }

    final newCastling = castling & _castleMask[from] & _castleMask[to];
    if (newCastling != castling) {
      hashLo ^=
          _zobrist.castlingLo[castling] ^ _zobrist.castlingLo[newCastling];
      hashHi ^=
          _zobrist.castlingHi[castling] ^ _zobrist.castlingHi[newCastling];
      castling = newCastling;
    }

    if (epSquare != -1) _xorEp(epSquare);
    epSquare = -1;
    if ((move & MoveBits.doublePush) != 0) {
      final enemyPawn = -us;
      if (_holds(to - 1, enemyPawn) || _holds(to + 1, enemyPawn)) {
        epSquare = from + 16 * us;
        _xorEp(epSquare);
      }
    }

    if (piece == 1 || piece == -1 || captured != 0) {
      halfmoveClock = 0;
    } else {
      halfmoveClock++;
    }
    if (us == -1) fullmoveNumber++;
    turn = -us;
    _xorSide();
  }

  /// Takes back the last move made with [makeMove].
  void unmakeMove() {
    final i = --_ply;
    final move = _undoMove[i];
    final captured = _undoCaptured[i];
    final from = move & 0x7F;
    final to = (move >> 7) & 0x7F;
    final promotion = (move >> 14) & 7;

    turn = -turn;
    final us = turn;
    if (us == -1) fullmoveNumber--;

    final placed = squares[to];
    final piece = promotion != 0 ? us : placed;
    squares[from] = piece;
    if ((move & MoveBits.enPassant) != 0) {
      squares[to] = 0;
      squares[to - 16 * us] = captured;
    } else {
      squares[to] = captured;
    }

    if ((move & MoveBits.castle) != 0) {
      final (rookFrom, rookTo) = _castlingRookSquares(to);
      squares[rookFrom] = squares[rookTo];
      squares[rookTo] = 0;
    }

    if (piece == 6) {
      whiteKing = from;
    } else if (piece == -6) {
      blackKing = from;
    }

    castling = _undoCastling[i];
    epSquare = _undoEp[i];
    halfmoveClock = _undoHalfmove[i];
    hashLo = _undoHashLo[i];
    hashHi = _undoHashHi[i];
  }

  /// Passes the turn without moving (used by null-move pruning and threat
  /// detection). Must be undone with [unmakeNullMove].
  void makeNullMove() {
    _pushUndo(0, 0);
    if (epSquare != -1) _xorEp(epSquare);
    epSquare = -1;
    halfmoveClock++;
    turn = -turn;
    _xorSide();
  }

  void unmakeNullMove() {
    final i = --_ply;
    turn = -turn;
    epSquare = _undoEp[i];
    halfmoveClock = _undoHalfmove[i];
    hashLo = _undoHashLo[i];
    hashHi = _undoHashHi[i];
  }

  static (int, int) _castlingRookSquares(int kingTo) => switch (kingTo) {
    6 => (7, 5),
    2 => (0, 3),
    118 => (119, 117),
    _ => (112, 115),
  };

  // ---------------------------------------------------------------------------
  // Draw detection helpers
  // ---------------------------------------------------------------------------

  /// Whether the current position occurred before since the last irreversible
  /// move ([occurrences] counts the earlier occurrences required).
  bool isRepetition({int occurrences = 1}) {
    var found = 0;
    final limit = _ply - halfmoveClock;
    for (var i = _ply - 2; i >= 0 && i >= limit; i -= 2) {
      if (_undoHashLo[i] == hashLo && _undoHashHi[i] == hashHi) {
        found++;
        if (found >= occurrences) return true;
      }
    }
    return false;
  }

  /// Whether neither side has enough material to deliver checkmate.
  bool get hasInsufficientMaterial {
    var minors = 0;
    var knights = 0;
    var lightBishops = 0;
    var darkBishops = 0;
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final type = squares[sq].abs();
      switch (type) {
        case 1 || 4 || 5:
          return false;
        case 2:
          minors++;
          knights++;
        case 3:
          minors++;
          if (((sq & 7) + (sq >> 4)).isOdd) {
            lightBishops++;
          } else {
            darkBishops++;
          }
      }
    }
    if (minors <= 1) return true;
    return knights == 0 && (lightBishops == 0 || darkBishops == 0);
  }

  /// Whether [side] still has material that could ever deliver mate.
  /// Used to decide flag-fall results: a side with a bare king or a lone
  /// minor piece cannot win on time.
  bool hasMatingMaterial(int side) {
    var minors = 0;
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final p = squares[sq];
      if (p == 0 || (p > 0) != (side > 0)) continue;
      switch (p.abs()) {
        case 1 || 4 || 5:
          return true;
        case 2 || 3:
          minors++;
      }
    }
    return minors >= 2;
  }

  /// Whether [side] has any piece other than pawns and the king.
  bool hasNonPawnMaterial(int side) {
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final p = squares[sq] * side;
      if (p >= 2 && p <= 5) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Conversions
  // ---------------------------------------------------------------------------

  /// Finds the legal encoded move matching a UCI string, or returns null.
  int? findMove(String uci) {
    if (uci.length < 4) return null;
    final int from;
    final int to;
    try {
      from = Square.to0x88(Square.parse(uci.substring(0, 2)));
      to = Square.to0x88(Square.parse(uci.substring(2, 4)));
    } on FormatException {
      return null;
    }
    final promotion = uci.length > 4
        ? PieceType.fromLetter(uci[4])?.code ?? 0
        : 0;
    for (final move in legalMoves()) {
      if (MoveBits.from(move) == from &&
          MoveBits.to(move) == to &&
          MoveBits.promotion(move) == promotion) {
        return move;
      }
    }
    return null;
  }

  /// Converts an encoded move (pseudo-legal in the current position) into a
  /// public [Move].
  Move decode(int move) {
    final from = MoveBits.from(move);
    final to = MoveBits.to(move);
    final piece = Piece.fromCode(squares[from])!;
    final promotionCode = MoveBits.promotion(move);
    Piece? captured;
    var kind = MoveKind.normal;
    if ((move & MoveBits.enPassant) != 0) {
      captured = Piece.fromCode(-turn);
      kind = MoveKind.enPassant;
    } else {
      captured = Piece.fromCode(squares[to]);
      if ((move & MoveBits.castle) != 0) {
        kind = (to & 7) == 6
            ? MoveKind.castleKingside
            : MoveKind.castleQueenside;
      } else if ((move & MoveBits.doublePush) != 0) {
        kind = MoveKind.doublePawnPush;
      }
    }
    return Move(
      from: Square.from0x88(from),
      to: Square.from0x88(to),
      piece: piece,
      captured: captured,
      promotion: promotionCode == 0 ? null : PieceType.fromCode(promotionCode),
      kind: kind,
    );
  }

  /// The piece on a 0..63 [square], or null.
  Piece? pieceAt(int square) => Piece.fromCode(squares[Square.to0x88(square)]);

  /// Total material of [side] in centipawns, excluding the king.
  int material(int side) {
    var total = 0;
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final p = squares[sq] * side;
      if (p > 0 && p < 6) total += pieceValues[p];
    }
    return total;
  }

  /// Creates an independent copy of the current position (without history).
  Board copyPosition() => Board.fromFen(toFen());
}

/// Deterministic Zobrist keys. Two 32-bit halves are used instead of one
/// 64-bit key so hashing behaves identically on native and web targets.
class _Zobrist {
  _Zobrist() {
    final random = Random(0x5EED);
    int next() => random.nextInt(0x40000000) << 2 | random.nextInt(4);
    for (var i = 0; i < pieceLo.length; i++) {
      pieceLo[i] = next();
      pieceHi[i] = next();
    }
    for (var i = 1; i < 16; i++) {
      castlingLo[i] = next();
      castlingHi[i] = next();
    }
    for (var i = 0; i < 8; i++) {
      epLo[i] = next();
      epHi[i] = next();
    }
    sideLo = next();
    sideHi = next();
  }

  final Uint32List pieceLo = Uint32List(13 * 128);
  final Uint32List pieceHi = Uint32List(13 * 128);
  final Uint32List castlingLo = Uint32List(16);
  final Uint32List castlingHi = Uint32List(16);
  final Uint32List epLo = Uint32List(8);
  final Uint32List epHi = Uint32List(8);
  late final int sideLo;
  late final int sideHi;
}
