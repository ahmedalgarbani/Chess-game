import 'dart:typed_data';

import 'package:chess_game/engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

int perft(Board board, int depth) {
  final moves = Int32List(256);
  final count = board.generateLegalMoves(moves, 0);
  if (depth == 1) return count;
  var nodes = 0;
  for (var i = 0; i < count; i++) {
    board.makeMove(moves[i]);
    nodes += perft(board, depth - 1);
    board.unmakeMove();
  }
  return nodes;
}

void main() {
  // Reference values from https://www.chessprogramming.org/Perft_Results
  final cases = <(String, String, List<int>)>[
    ('initial', startingFen, [20, 400, 8902, 197281]),
    (
      'kiwipete',
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
      [48, 2039, 97862],
    ),
    (
      'position 3',
      '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
      [14, 191, 2812, 43238],
    ),
    (
      'position 4',
      'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1',
      [6, 264, 9467],
    ),
    (
      'position 5',
      'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8',
      [44, 1486, 62379],
    ),
    (
      'position 6',
      'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10',
      [46, 2079, 89890],
    ),
  ];

  for (final (name, fen, expected) in cases) {
    test('perft $name', () {
      final board = Board.fromFen(fen);
      final hashLo = board.hashLo;
      final hashHi = board.hashHi;
      for (var depth = 1; depth <= expected.length; depth++) {
        expect(
          perft(board, depth),
          expected[depth - 1],
          reason: 'depth $depth',
        );
      }
      // make/unmake must restore the exact position and hash.
      expect(board.toFen(), Board.fromFen(fen).toFen());
      expect(board.hashLo, hashLo);
      expect(board.hashHi, hashHi);
    });
  }

  test('incremental hash matches a freshly loaded position', () {
    final board = Board.fromFen(
      'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
    );
    final moves = board.legalMoves();
    for (final move in moves) {
      board.makeMove(move);
      final fresh = Board.fromFen(board.toFen());
      expect(board.hashLo, fresh.hashLo, reason: board.toFen());
      expect(board.hashHi, fresh.hashHi, reason: board.toFen());
      board.unmakeMove();
    }
  });
}
