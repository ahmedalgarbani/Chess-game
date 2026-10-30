import 'puzzle.dart';

/// The built-in puzzles, from easy mates to multi-move combinations.
/// Every line is checked by `test/features/puzzles_test.dart`.
abstract final class PuzzleCatalog {
  static const puzzles = <Puzzle>[
    // Mate in one.
    Puzzle(
      id: 'back-rank',
      fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
      solution: ['a1a8'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'queen-corner',
      fen: 'k7/8/1K6/8/8/8/8/7Q w - - 0 1',
      solution: ['h1h8'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'black-back-rank',
      fen: 'r5k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1',
      solution: ['a8a1'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'scholars-mate',
      fen:
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
      solution: ['h5f7'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'fools-mate',
      fen: 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2',
      solution: ['d8h4'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'promotion-mate',
      fen: 'k7/2P5/1K6/8/8/8/8/8 w - - 0 1',
      solution: ['c7c8q'],
      theme: PuzzleTheme.promotion,
      difficulty: 1,
    ),
    Puzzle(
      id: 'kiss-of-death',
      fen: '7k/8/5KQ1/8/8/8/8/8 w - - 0 1',
      solution: ['g6g7'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'smothered',
      fen: '6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1',
      solution: ['g5f7'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'black-smothered',
      fen: '6k1/8/8/8/6n1/8/6PP/6RK b - - 0 1',
      solution: ['g4f2'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'two-rooks',
      fen: 'k7/7R/8/8/8/8/8/2R4K w - - 0 1',
      solution: ['c1c8'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 1,
    ),
    Puzzle(
      id: 'arabian-mate',
      fen: '7k/1R6/5N2/8/8/8/8/K7 w - - 0 1',
      solution: ['b7h7'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 2,
    ),
    Puzzle(
      id: 'epaulette',
      fen: '3rkr2/8/8/8/8/1Q6/8/4K3 w - - 0 1',
      solution: ['b3e6'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 2,
    ),
    Puzzle(
      id: 'knight-guard',
      fen: '6k1/5ppp/8/8/7n/5q2/5PPP/R6K b - - 0 1',
      solution: ['f3g2'],
      theme: PuzzleTheme.mateIn1,
      difficulty: 2,
    ),
    // Winning material.
    Puzzle(
      id: 'knight-fork-rook',
      fen: 'r3k3/pp6/8/1N6/8/8/PP6/4K3 w - - 0 1',
      solution: ['b5c7', 'e8e7', 'c7a8'],
      theme: PuzzleTheme.fork,
      difficulty: 1,
    ),
    Puzzle(
      id: 'knight-fork-queen',
      fen: '3q4/p5k1/1p6/8/3N4/8/PP3PPP/6K1 w - - 0 1',
      solution: ['d4e6', 'g7f6', 'e6d8'],
      theme: PuzzleTheme.fork,
      difficulty: 2,
    ),
    Puzzle(
      id: 'pawn-fork',
      fen: '6k1/p4ppp/2n1r3/8/3P4/6P1/5P1P/1R4K1 w - - 0 1',
      solution: ['d4d5', 'e6e8', 'd5c6'],
      theme: PuzzleTheme.fork,
      difficulty: 1,
    ),
    Puzzle(
      id: 'queen-fork',
      fen: '3q2k1/5ppp/8/8/8/8/P5PP/R5K1 b - - 0 1',
      solution: ['d8d4', 'g1h1', 'd4a1'],
      theme: PuzzleTheme.fork,
      difficulty: 2,
    ),
    Puzzle(
      id: 'bishop-skewer',
      fen: '6q1/pp4pp/4k3/8/8/8/PP3PPP/5BK1 w - - 0 1',
      solution: ['f1c4', 'e6e7', 'c4g8'],
      theme: PuzzleTheme.skewer,
      difficulty: 2,
    ),
    Puzzle(
      id: 'rook-skewer',
      fen: '8/p4pp1/8/3k3q/8/8/5PPP/R5K1 w - - 0 1',
      solution: ['a1a5', 'd5e6', 'a5h5'],
      theme: PuzzleTheme.skewer,
      difficulty: 2,
    ),
    Puzzle(
      id: 'bishop-pin',
      fen: '4k3/pp1q1ppp/8/8/P7/8/1P3PPP/2R2BK1 w - - 0 1',
      solution: ['f1b5', 'd7b5', 'a4b5'],
      theme: PuzzleTheme.pin,
      difficulty: 2,
    ),
    Puzzle(
      id: 'discovered-check',
      fen: '6k1/pp2qppp/8/8/4N3/8/PP3PPP/4R1K1 w - - 0 1',
      solution: ['e4f6', 'g7f6', 'e1e7'],
      theme: PuzzleTheme.winMaterial,
      difficulty: 2,
    ),
    // Mate in two.
    Puzzle(
      id: 'rook-roller',
      fen: '6k1/8/8/8/8/8/R7/1R4K1 w - - 0 1',
      solution: ['a2a7', 'g8f8', 'b1b8'],
      theme: PuzzleTheme.mateIn2,
      difficulty: 2,
    ),
    Puzzle(
      id: 'black-rook-roller',
      fen: '1r4k1/r7/8/8/8/8/8/6K1 b - - 0 1',
      solution: ['a7a2', 'g1f1', 'b8b1'],
      theme: PuzzleTheme.mateIn2,
      difficulty: 2,
    ),
    Puzzle(
      id: 'promotion-breakthrough',
      fen: '1r4k1/1P3ppp/8/8/8/8/5PPP/2R3K1 w - - 0 1',
      solution: ['c1c8', 'b8c8', 'b7c8q'],
      theme: PuzzleTheme.promotion,
      difficulty: 2,
    ),
    Puzzle(
      id: 'philidor-legacy',
      fen: 'r6k/pp4pp/7N/3Q4/8/8/5PPP/6K1 w - - 0 1',
      solution: ['d5g8', 'a8g8', 'h6f7'],
      theme: PuzzleTheme.mateIn2,
      difficulty: 3,
    ),
    Puzzle(
      id: 'legals-mate',
      fen: 'rn1qkbnr/ppp2p1p/3p2p1/4N3/2B1P3/2N5/PPPP1PPP/R1BbK2R w KQkq - 0 6',
      solution: ['c4f7', 'e8e7', 'c3d5'],
      theme: PuzzleTheme.mateIn2,
      difficulty: 3,
    ),
    Puzzle(
      id: 'opera-game',
      fen: '4kb1r/p2n1ppp/4q3/4p1B1/4P3/1Q6/PPP2PPP/2KR4 w - - 1 16',
      solution: ['b3b8', 'd7b8', 'd1d8'],
      theme: PuzzleTheme.mateIn2,
      difficulty: 3,
    ),
    Puzzle(
      id: 'bodens-mate',
      fen: '2kr3r/pp1n1ppp/2n5/8/5B2/5Q2/PPP2PPP/R4BK1 w - - 0 1',
      solution: ['f3c6', 'b7c6', 'f1a6'],
      theme: PuzzleTheme.mateIn2,
      difficulty: 3,
    ),
  ];

  static Puzzle? byId(String id) =>
      puzzles.where((p) => p.id == id).firstOrNull;

  /// The puzzle of the day for the local calendar day of [now].
  static Puzzle daily(DateTime now) {
    final day = DateTime.utc(now.year, now.month, now.day);
    final index = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return puzzles[index % puzzles.length];
  }
}
