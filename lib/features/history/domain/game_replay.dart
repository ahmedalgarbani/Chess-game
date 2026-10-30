import '../../../engine/chess_engine.dart';

/// Every position of a recorded game, for stepping through it.
class GameReplay {
  GameReplay._(this.moves, this.sans, this.positions, this.checks);

  /// Replays [uciMoves] from the starting position, stopping at the first
  /// illegal move.
  factory GameReplay(List<String> uciMoves) {
    final game = ChessGame();
    final moves = <Move>[];
    final sans = <String>[];
    final positions = [game.pieces];
    final checks = <int?>[null];
    for (final uci in uciMoves) {
      final move = game.moveFromUci(uci);
      if (move == null) break;
      sans.add(game.sanOf(move));
      game.play(move);
      moves.add(move);
      positions.add(game.pieces);
      checks.add(game.isCheck ? game.kingSquare(game.turn) : null);
    }
    return GameReplay._(moves, sans, positions, checks);
  }

  final List<Move> moves;
  final List<String> sans;

  /// The board after each ply; index 0 is the starting position.
  final List<List<Piece?>> positions;

  /// The checked king's square after each ply.
  final List<int?> checks;

  int get length => moves.length;

  /// The moves played up to [ply], in UCI notation.
  List<String> uciUpTo(int ply) => [for (final m in moves.take(ply)) m.uci];
}
