import 'dart:typed_data';

import '../src/board.dart';
import '../src/square.dart';

/// Fast tactical pattern detection used by the coach and the blunder guard.
///
/// These are heuristics, not a search: they ignore pins and x-rays, which is
/// fine for spotting the loose pieces beginners typically leave behind.
abstract final class Tactics {
  /// Simplified piece values in pawns, indexed by piece code magnitude.
  static const List<int> values = [0, 1, 3, 3, 5, 9, 100];

  /// Squares (0..63) of pieces of [side] (excluding the king) that are
  /// attacked and either undefended or attacked by a cheaper piece.
  static List<int> hangingPieces(Board board, int side) {
    final result = <int>[];
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final piece = board.squares[sq] * side;
      if (piece <= 0 || piece == 6) continue;
      if (_isHanging(board, sq, piece, side)) result.add(Square.from0x88(sq));
    }
    return result;
  }

  /// Highest value (in pawns) among the hanging pieces of [side], or 0.
  static int worstHangingValue(Board board, int side) {
    var worst = 0;
    for (final square in hangingPieces(board, side)) {
      final value = values[board.squares[Square.to0x88(square)].abs()];
      if (value > worst) worst = value;
    }
    return worst;
  }

  static bool _isHanging(Board board, int sq, int pieceCode, int side) {
    final attacker = board.leastValuableAttacker(sq, -side);
    if (attacker == 0) return false;
    if (!board.isAttacked(sq, side)) return true;
    return values[attacker] < values[pieceCode];
  }

  /// A UCI move that checkmates immediately for the side to move, or null.
  static String? mateInOne(Board board) {
    final moves = Int32List(256);
    final count = board.generateLegalMoves(moves, 0);
    for (var i = 0; i < count; i++) {
      final move = moves[i];
      board.makeMove(move);
      final mated = board.inCheck && !board.hasLegalMove();
      board.unmakeMove();
      if (mated) return board.decode(move).uci;
    }
    return null;
  }

  /// Squares (0..63) of enemy pieces attacked by the piece standing on
  /// [square] that are worth attacking (undefended, or more valuable than
  /// the attacker). Used to explain threats created by a move.
  static List<int> targetsOfPiece(Board board, int square) {
    final sq = Square.to0x88(square);
    final piece = board.squares[sq];
    if (piece == 0) return const [];
    final side = piece > 0 ? 1 : -1;
    final type = piece.abs();
    final targets = <int>[];

    void consider(int target) {
      final victim = board.squares[target];
      if (victim == 0 || (victim > 0) == (side > 0)) return;
      final victimType = victim.abs();
      if (victimType == 6) return;
      final defended = board.isAttacked(target, -side);
      if (!defended || values[victimType] > values[type]) {
        targets.add(Square.from0x88(target));
      }
    }

    switch (type) {
      case 1:
        for (final d in side == 1 ? const [15, 17] : const [-15, -17]) {
          final t = sq + d;
          if ((t & 0x88) == 0) consider(t);
        }
      case 2 || 6:
        for (final d in type == 2 ? Board.knightOffsets : Board.kingOffsets) {
          final t = sq + d;
          if ((t & 0x88) == 0) consider(t);
        }
      default:
        final directions = [
          if (type == 3 || type == 5) ...Board.diagonalOffsets,
          if (type == 4 || type == 5) ...Board.orthogonalOffsets,
        ];
        for (final d in directions) {
          var t = sq + d;
          while ((t & 0x88) == 0) {
            if (board.squares[t] != 0) {
              consider(t);
              break;
            }
            t += d;
          }
        }
    }
    return targets;
  }

  /// Whether the encoded [move] looks risky for the side making it: it
  /// leaves a piece worth at least a minor hanging, or allows mate in one.
  /// A cheap pre-filter before asking the engine for a verdict.
  static bool looksRisky(Board board, int move) {
    final side = board.turn;
    board.makeMove(move);
    final risky =
        worstHangingValue(board, side) >= 3 || mateInOne(board) != null;
    board.unmakeMove();
    return risky;
  }
}
