/// A self-contained chess engine: rules, notation and an AI player.
///
/// Pure Dart with no Flutter dependency, so it can run inside isolates and
/// be unit-tested in isolation.
library;

export 'src/board.dart' show Board, MoveBits, startingFen;
export 'src/game.dart';
export 'src/move.dart';
export 'src/piece.dart';
export 'src/square.dart';
