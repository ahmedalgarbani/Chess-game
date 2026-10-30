import '../../../engine/chess_engine.dart';

/// A small exhaustive search for short forced mates, used to accept any
/// correct solution of a mate puzzle and not only the catalogued one.
abstract final class MateSearch {
  /// Whether the side to move is checkmated.
  static bool isMate(Board board) => board.inCheck && !board.hasLegalMove();

  /// Whether the side to move can mate within [moves] of its own moves.
  static bool canMate(Board board, int moves) {
    for (final move in board.legalMoves()) {
      board.makeMove(move);
      final mates =
          isMate(board) || (moves > 1 && everyReplyLoses(board, moves - 1));
      board.unmakeMove();
      if (mates) return true;
    }
    return false;
  }

  /// Whether every reply of the side to move still allows the opponent to
  /// mate within [moves] of its own moves. False on stalemate.
  static bool everyReplyLoses(Board board, int moves) {
    final replies = board.legalMoves();
    if (replies.isEmpty) return false;
    for (final reply in replies) {
      board.makeMove(reply);
      final lost = canMate(board, moves);
      board.unmakeMove();
      if (!lost) return false;
    }
    return true;
  }
}
