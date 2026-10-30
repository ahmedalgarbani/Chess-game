import 'dart:math';

import '../src/board.dart';
import 'evaluator.dart';
import 'searcher.dart';
import 'tactics.dart';
import 'transposition_table.dart';

/// How strongly the engine plays.
///
/// Full-strength skills use a time-bounded iterative deepening search.
/// Weaker skills score every move exactly and then add [noise] and random
/// [blunderChance] mistakes, which makes them lose in a human-like way.
class EngineSkill {
  const EngineSkill({
    required this.depth,
    this.timeLimitMs,
    this.noise = 0,
    this.blunderChance = 0,
    this.quiescence = true,
  });

  final int depth;
  final int? timeLimitMs;

  /// Maximum random error in centipawns added to each candidate move.
  final int noise;

  /// Probability of picking a random, merely playable move.
  final double blunderChance;

  /// Whether capture sequences are resolved at the leaves.
  final bool quiescence;

  bool get isFullStrength => noise == 0 && blunderChance == 0;
}

/// A move chosen by the engine.
class EngineMove {
  const EngineMove({required this.uci, required this.score});

  final String uci;

  /// Score in centipawns from the mover's point of view.
  final int score;
}

/// Evaluation of a position, always reported from white's point of view.
class PositionAnalysis {
  const PositionAnalysis({
    required this.bestMove,
    required this.scoreWhite,
    required this.mateIn,
    required this.principalVariation,
    required this.threat,
    required this.depth,
  });

  /// Best move for the side to move (UCI), or null if the game is over.
  final String? bestMove;

  /// Centipawns from white's point of view (mates are clamped to ±10000).
  final int scoreWhite;

  /// Moves until mate: positive when white mates, negative when black does.
  final int? mateIn;

  /// Expected continuation in UCI notation, starting with [bestMove].
  final List<String> principalVariation;

  /// What the opponent would play if the side to move passed (UCI), when
  /// that would win material or mate. Null when there is no real threat.
  final String? threat;

  final int depth;
}

/// The engine's verdict on a candidate move (used by the blunder guard).
class MoveReview {
  const MoveReview({
    required this.lossCp,
    required this.bestMove,
    required this.refutation,
    required this.allowsMate,
  });

  /// How much worse the move is than the best move, in centipawns.
  final int lossCp;

  /// The best move in the position (UCI).
  final String? bestMove;

  /// The opponent's strongest reply to the candidate move (UCI).
  final String? refutation;

  /// Whether the move allows a forced mate.
  final bool allowsMate;

  bool get isBlunder => allowsMate || lossCp >= 200;
}

/// Entry points for everything the app asks of the engine. All functions
/// are synchronous and self-contained so they can run in a background
/// isolate.
abstract final class ChessAi {
  /// Builds a board by replaying [moves] (UCI) from [startFen].
  static Board replay(String startFen, List<String> moves) {
    final board = Board.fromFen(startFen);
    for (final uci in moves) {
      final move = board.findMove(uci);
      if (move == null) throw ArgumentError.value(uci, 'moves', 'Illegal');
      board.makeMove(move);
    }
    return board;
  }

  /// Picks a move for the side to move according to [skill]. Returns null
  /// when there is no legal move.
  static EngineMove? chooseMove(
    Board board,
    EngineSkill skill, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final searcher = Searcher(board);

    if (skill.isFullStrength) {
      final outcome = searcher.search(
        maxDepth: skill.depth,
        timeLimitMs: skill.timeLimitMs,
      );
      if (outcome.bestMove == 0) return null;
      return EngineMove(
        uci: board.decode(outcome.bestMove).uci,
        score: outcome.score,
      );
    }

    final scored = searcher.scoreRootMoves(
      skill.depth,
      quiescence: skill.quiescence,
    );
    if (scored.isEmpty) return null;

    // Even weak players spot a mate in one.
    var pick = scored.first;
    if (!(SearchScore.isMate(pick.score) && pick.score > 0)) {
      if (rng.nextDouble() < skill.blunderChance) {
        final pool = max(1, (scored.length * 0.6).ceil());
        pick = scored[rng.nextInt(pool)];
      } else {
        var bestNoisy = -SearchScore.infinity;
        for (final candidate in scored) {
          final noisy =
              candidate.score + rng.nextInt(2 * skill.noise + 1) - skill.noise;
          if (noisy > bestNoisy) {
            bestNoisy = noisy;
            pick = candidate;
          }
        }
      }
    }
    return EngineMove(uci: board.decode(pick.move).uci, score: pick.score);
  }

  /// Analyses the position: best move, evaluation, expected line and the
  /// opponent's threat.
  static PositionAnalysis analyze(
    Board board, {
    int maxDepth = 10,
    int timeLimitMs = 500,
    bool includeThreat = true,
  }) {
    final searcher = Searcher(board);
    final outcome = searcher.search(
      maxDepth: maxDepth,
      timeLimitMs: timeLimitMs,
    );
    final side = board.turn;

    final pv = <String>[];
    var plies = 0;
    for (final move in outcome.principalVariation) {
      final legal = board.legalMoves();
      if (!legal.contains(move)) break;
      pv.add(board.decode(move).uci);
      board.makeMove(move);
      plies++;
    }
    for (var i = 0; i < plies; i++) {
      board.unmakeMove();
    }

    String? threat;
    if (includeThreat && !board.inCheck && outcome.bestMove != 0) {
      threat = _findThreat(board, outcome.score);
    }

    final mate = SearchScore.isMate(outcome.score)
        ? SearchScore.mateInMoves(outcome.score) * side
        : null;
    final clamped = outcome.score.clamp(-10000, 10000);
    return PositionAnalysis(
      bestMove: outcome.bestMove == 0
          ? null
          : board.decode(outcome.bestMove).uci,
      scoreWhite: clamped * side,
      mateIn: mate,
      principalVariation: pv,
      threat: threat,
      depth: outcome.depth,
    );
  }

  /// Compares the encoded [move] against the best move in the position.
  static MoveReview reviewMove(
    Board board,
    int move, {
    int maxDepth = 4,
    int timeLimitMs = 300,
  }) {
    final best = Searcher(board)
        .search(maxDepth: maxDepth, timeLimitMs: timeLimitMs);
    board.makeMove(move);
    final reply = Searcher(
      board,
      table: TranspositionTable(sizeLog2: 16),
    ).search(maxDepth: maxDepth - 1, timeLimitMs: timeLimitMs);
    final refutation = reply.bestMove == 0
        ? null
        : board.decode(reply.bestMove).uci;
    board.unmakeMove();

    final candidateScore = -reply.score;
    final allowsMate = SearchScore.isMate(reply.score) && reply.score > 0;
    final loss = max(0, best.score - candidateScore);
    return MoveReview(
      lossCp: loss,
      bestMove: best.bestMove == 0 ? null : board.decode(best.bestMove).uci,
      refutation: refutation,
      allowsMate: allowsMate,
    );
  }

  /// Static evaluation from white's point of view (no search).
  static int staticEvaluation(Board board) =>
      Evaluator.evaluate(board) * board.turn;

  static String? _findThreat(Board board, int currentScore) {
    board.makeNullMove();
    final outcome = Searcher(
      board,
      table: TranspositionTable(sizeLog2: 15),
    ).search(maxDepth: 3, timeLimitMs: 150);
    String? threat;
    if (outcome.bestMove != 0) {
      final scoreForUs = -outcome.score;
      final mates = SearchScore.isMate(outcome.score) && outcome.score > 0;
      if (mates || currentScore - scoreForUs >= 150) {
        threat = board.decode(outcome.bestMove).uci;
      }
    }
    board.unmakeNullMove();
    return threat;
  }

  /// Whether [move] deserves a full engine review (see [Tactics.looksRisky]).
  static bool needsReview(Board board, int move) =>
      Tactics.looksRisky(board, move);
}
