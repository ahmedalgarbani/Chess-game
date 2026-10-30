import 'dart:math';

import 'package:chess_game/engine/chess_ai.dart';
import 'package:chess_game/engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strong = EngineSkill(depth: 6, timeLimitMs: 3000);

  test('finds a mate in one', () {
    final board = Board.fromFen('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
    final move = ChessAi.chooseMove(board, strong)!;
    expect(move.uci, 'd1d8');
  });

  test('finds a mate in two', () {
    // Rook ladder: 1. Ra7 and 2. Rb8#.
    final board = Board.fromFen('6k1/8/8/8/8/8/R7/1R4K1 w - - 0 1');
    final analysis = ChessAi.analyze(board, maxDepth: 6, timeLimitMs: 3000);
    expect(analysis.mateIn, 2);
  });

  test('captures a free queen', () {
    final board = Board.fromFen('4k3/8/8/3q4/8/2N5/8/4K3 w - - 0 1');
    final move = ChessAi.chooseMove(board, strong)!;
    expect(move.uci, 'c3d5');
  });

  test('weak skills still play legal moves and spot mates', () {
    const weakest = EngineSkill(
      depth: 1,
      noise: 250,
      blunderChance: 0.25,
      quiescence: false,
    );
    final rng = Random(1);
    final board = Board.fromFen(startingFen);
    for (var i = 0; i < 20; i++) {
      final move = ChessAi.chooseMove(board, weakest, random: rng);
      if (move == null) break;
      board.makeMove(board.findMove(move.uci)!);
    }
    final mateBoard = Board.fromFen('6k1/5ppp/8/8/8/8/5PPP/3R2K1 w - - 0 1');
    expect(ChessAi.chooseMove(mateBoard, weakest, random: rng)!.uci, 'd1d8');
  });

  test('analysis reports expected line and threats', () {
    // The bishop on b2 attacks the white rook on a1.
    final board = Board.fromFen('4k3/8/8/8/8/8/1b6/R3K3 w - - 0 1');
    final analysis = ChessAi.analyze(board, timeLimitMs: 800);
    expect(analysis.principalVariation, isNotEmpty);
    expect(analysis.threat, 'b2a1');
  });

  test('review flags a blunder that hangs the queen', () {
    final board = Board.fromFen('4k3/8/8/8/8/2n5/8/3QK3 w - - 0 1');
    // e2 is attacked by the knight on c3.
    final queenEnPrise = board.findMove('d1e2')!;
    final review = ChessAi.reviewMove(board, queenEnPrise);
    expect(review.isBlunder, isTrue);
    expect(review.refutation, 'c3e2');
    expect(ChessAi.needsReview(board, queenEnPrise), isTrue);

    final safe = board.findMove('d1d4')!;
    expect(ChessAi.reviewMove(board, safe).isBlunder, isFalse);
  });

  test('hanging pieces detection', () {
    final board = Board.fromFen('4k3/8/8/3n4/8/8/8/3RK3 w - - 0 1');
    expect(Tactics.hangingPieces(board, -1), [Square.parse('d5')]);
    expect(Tactics.hangingPieces(board, 1), isEmpty);
  });

  test('converts king and rook versus king', () {
    final board = Board.fromFen('8/8/8/4k3/8/8/8/R3K3 w - - 0 1');
    const skill = EngineSkill(depth: 5, timeLimitMs: 400);
    var plies = 0;
    while (board.hasLegalMove() && plies < 120 && board.halfmoveClock < 100) {
      final move = ChessAi.chooseMove(board, skill)!;
      board.makeMove(board.findMove(move.uci)!);
      plies++;
    }
    expect(
      board.inCheck && !board.hasLegalMove(),
      isTrue,
      reason: 'not mated after $plies plies: ${board.toFen()}',
    );
  });
}
