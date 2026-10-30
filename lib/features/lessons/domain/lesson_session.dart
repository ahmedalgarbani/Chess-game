import '../../../engine/chess_engine.dart';
import 'lesson.dart';

enum LessonMoveResult {
  /// The move was fine; the learner keeps playing.
  progress,

  /// The goal of the step is complete.
  solved,

  /// The move does not achieve the goal and has been taken back.
  wrong,
}

/// The rules of one lesson step: which moves are allowed and when the goal
/// is reached. In free-play goals only the learner moves, so the turn is
/// handed back after every move.
class LessonSession {
  LessonSession(this.step)
    : board = Board.fromFen(step.fen),
      _remainingStars = {
        if (step.goal case CollectStarsGoal(:final stars))
          for (final star in stars) Square.parse(star),
      } {
    learner = board.turn;
  }

  final LessonStep step;
  final Board board;
  final Set<int> _remainingStars;
  late final int learner;
  bool _solved = false;

  bool get isInfo => step.goal == null;

  bool get isSolved => isInfo || _solved;

  PieceColor get learnerColor => PieceColor.fromSign(learner);

  Set<int> get remainingStars => Set.unmodifiable(_remainingStars);

  List<Piece?> get pieces => List.generate(64, board.pieceAt, growable: false);

  List<Move> legalMovesFrom(int square) {
    if (isSolved) return const [];
    return [
      for (final encoded in board.legalMoves())
        if (Square.from0x88(MoveBits.from(encoded)) == square)
          board.decode(encoded),
    ];
  }

  /// Plays [move] (which must come from [legalMovesFrom]).
  LessonMoveResult play(Move move) {
    final encoded = board.findMove(move.uci);
    if (encoded == null || isSolved) return LessonMoveResult.wrong;
    board.makeMove(encoded);

    switch (step.goal) {
      case CollectStarsGoal():
        _remainingStars.remove(move.to);
        if (_remainingStars.isEmpty) return _solve();
        board.setTurn(learner);
        return LessonMoveResult.progress;
      case CaptureAllGoal():
        if (!_enemyHasPieces()) return _solve();
        board.setTurn(learner);
        return LessonMoveResult.progress;
      case CheckmateGoal():
        if (board.inCheck && !board.hasLegalMove()) return _solve();
      case SpecialMoveGoal(:final kinds, :final promotion):
        if (kinds.contains(move.kind) || (promotion && move.isPromotion)) {
          return _solve();
        }
      case PlayMoveGoal(:final moves):
        if (moves.contains(move.uci)) return _solve();
      case null:
        break;
    }
    board.unmakeMove();
    return LessonMoveResult.wrong;
  }

  LessonMoveResult _solve() {
    _solved = true;
    return LessonMoveResult.solved;
  }

  bool _enemyHasPieces() {
    final enemy = -learner;
    for (var square = 0; square < 64; square++) {
      final piece = board.pieceAt(square);
      if (piece != null &&
          piece.color.sign == enemy &&
          piece.type != PieceType.king) {
        return true;
      }
    }
    return false;
  }
}
