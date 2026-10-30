import '../../../engine/chess_engine.dart';
import 'mate_search.dart';
import 'puzzle.dart';

enum PuzzleMoveResult {
  /// Right move; the opponent has replied and the solver goes on.
  correct,

  /// The puzzle is complete.
  solved,

  /// Not the solution; the move has been taken back.
  wrong,
}

/// The rules of one puzzle attempt. The catalogued line is followed, but
/// any checkmate is accepted, and in mate puzzles so is any move that still
/// forces mate in time.
class PuzzleSession {
  PuzzleSession(this.puzzle)
    : _game = ChessGame(fen: puzzle.fen),
      _movesLeft = puzzle.solverMoves {
    solverColor = _game.turn;
  }

  final Puzzle puzzle;
  final ChessGame _game;
  late final PieceColor solverColor;

  /// Index of the next catalogued solver move; null once the solver has
  /// found a different winning line.
  int? _step = 0;
  int _movesLeft;
  bool _solved = false;

  bool get isSolved => _solved;

  List<Piece?> get pieces => _game.pieces;

  Move? get lastMove => _game.lastMove;

  List<Move> legalMovesFrom(int square) => _solved || _game.turn != solverColor
      ? const []
      : _game.legalMovesFrom(square);

  /// The square of the piece to move next, for hints.
  int? get hintSquare {
    if (_solved) return null;
    final step = _step;
    if (step != null) {
      return Square.parse(puzzle.solution[step].substring(0, 2));
    }
    final board = Board.fromFen(_game.fen);
    for (final encoded in board.legalMoves()) {
      board.makeMove(encoded);
      final mates =
          MateSearch.isMate(board) ||
          (_movesLeft > 1 && MateSearch.everyReplyLoses(board, _movesLeft - 1));
      board.unmakeMove();
      if (mates) return Square.from0x88(MoveBits.from(encoded));
    }
    return null;
  }

  /// Plays the solver's [move]. After [PuzzleMoveResult.correct] the
  /// opponent answers with [playReply].
  PuzzleMoveResult play(Move move) {
    if (_solved || _game.turn != solverColor) return PuzzleMoveResult.wrong;
    final step = _step;
    _game.play(move);
    if (_game.isCheckmate) return _solve();

    final scripted = step != null && puzzle.solution[step] == move.uci;
    if (!scripted && !_stillMates()) {
      _game.undo();
      return PuzzleMoveResult.wrong;
    }
    _movesLeft--;
    if (scripted && step + 1 >= puzzle.solution.length) return _solve();
    _step = scripted ? step + 2 : null;
    return PuzzleMoveResult.correct;
  }

  /// Plays the opponent's answer to a correct move: the catalogued reply,
  /// or any reply once the solver has left the catalogued line.
  Move? playReply() {
    if (_solved || _game.turn == solverColor) return null;
    final step = _step;
    final reply = step != null
        ? _game.moveFromUci(puzzle.solution[step - 1])
        : _game.legalMoves.firstOrNull;
    if (reply != null) _game.play(reply);
    return reply;
  }

  bool _stillMates() =>
      puzzle.theme.isMate &&
      _movesLeft > 1 &&
      MateSearch.everyReplyLoses(Board.fromFen(_game.fen), _movesLeft - 1);

  PuzzleMoveResult _solve() {
    _solved = true;
    return PuzzleMoveResult.solved;
  }
}
