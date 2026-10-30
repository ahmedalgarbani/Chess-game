/// The tactical idea a puzzle trains.
enum PuzzleTheme {
  mateIn1,
  mateIn2,
  fork,
  skewer,
  pin,
  promotion,
  winMaterial;

  bool get isMate => this == mateIn1 || this == mateIn2;
}

/// A position with a winning line to find.
class Puzzle {
  const Puzzle({
    required this.id,
    required this.fen,
    required this.solution,
    required this.theme,
    required this.difficulty,
  });

  final String id;
  final String fen;

  /// UCI moves alternating the solver's moves and the opponent's replies,
  /// starting and ending with a move of the solver.
  final List<String> solution;
  final PuzzleTheme theme;

  /// 1 (easy) to 3 (hard).
  final int difficulty;

  int get coins => 5 + 10 * difficulty;

  int get xp => 20 * difficulty;

  /// How many moves the solver has to find.
  int get solverMoves => (solution.length + 1) ~/ 2;
}
