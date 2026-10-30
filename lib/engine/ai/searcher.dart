import 'dart:typed_data';

import '../src/board.dart';
import 'evaluator.dart';
import 'transposition_table.dart';

/// Score bounds used by the search.
abstract final class SearchScore {
  static const int infinity = 1000000;
  static const int mate = 30000;

  /// Scores beyond this magnitude encode a forced mate.
  static const int mateThreshold = mate - Searcher.maxPly;

  static bool isMate(int score) => score.abs() >= mateThreshold;

  /// Number of moves (not plies) until mate, positive when the side to move
  /// mates and negative when it gets mated.
  static int mateInMoves(int score) {
    final plies = mate - score.abs();
    final moves = (plies + 1) ~/ 2;
    return score > 0 ? moves : -moves;
  }
}

/// The result of a search: best move, score and principal variation.
class SearchOutcome {
  const SearchOutcome({
    required this.bestMove,
    required this.score,
    required this.depth,
    required this.principalVariation,
    required this.nodes,
  });

  /// Encoded best move, or 0 when the side to move has no legal move.
  final int bestMove;

  /// Score in centipawns from the side to move's point of view.
  final int score;
  final int depth;
  final List<int> principalVariation;
  final int nodes;
}

/// A root move with an exact score (see [Searcher.scoreRootMoves]).
class ScoredMove {
  const ScoredMove(this.move, this.score);

  final int move;
  final int score;
}

/// Alpha-beta searcher with iterative deepening, principal variation search,
/// a transposition table, null-move pruning, late move reductions, killer
/// and history move ordering, and a quiescence search.
class Searcher {
  Searcher(this.board, {TranspositionTable? table})
    : _table = table ?? TranspositionTable();

  static const int maxPly = 64;
  static const int _movesPerPly = 256;

  final Board board;
  final TranspositionTable _table;

  final Int32List _moves = Int32List(maxPly * _movesPerPly);
  final Int32List _orderScores = Int32List(maxPly * _movesPerPly);
  final Int32List _killers = Int32List(maxPly * 2);
  final Int32List _history = Int32List(13 * 128);
  final Int32List _pvTable = Int32List(maxPly * maxPly);
  final Int32List _pvLength = Int32List(maxPly);

  final Stopwatch _clock = Stopwatch();
  int _timeLimitMs = 0;
  int _nodes = 0;
  bool _stopped = false;
  bool _canStop = false;

  /// Runs an iterative deepening search up to [maxDepth] plies, optionally
  /// bounded by [timeLimitMs] milliseconds.
  SearchOutcome search({required int maxDepth, int? timeLimitMs}) {
    _prepare(timeLimitMs);
    final rootMoves = board.legalMoves();
    if (rootMoves.isEmpty) {
      return SearchOutcome(
        bestMove: 0,
        score: board.inCheck ? -SearchScore.mate : 0,
        depth: 0,
        principalVariation: const [],
        nodes: 0,
      );
    }

    var bestMove = rootMoves.first;
    var bestScore = 0;
    var completedDepth = 0;
    var pv = <int>[bestMove];
    final depthLimit = maxDepth.clamp(1, maxPly - 8);

    for (var depth = 1; depth <= depthLimit; depth++) {
      _canStop = depth > 1;
      final score = _negamax(
        depth,
        -SearchScore.infinity,
        SearchScore.infinity,
        0,
        allowNull: false,
      );
      if (_stopped) break;
      completedDepth = depth;
      bestScore = score;
      if (_pvLength[0] > 0) {
        bestMove = _pvTable[0];
        pv = List<int>.generate(_pvLength[0], (i) => _pvTable[i]);
      }
      if (SearchScore.isMate(score)) break;
      if (timeLimitMs != null &&
          _clock.elapsedMilliseconds > timeLimitMs * 0.55) {
        break;
      }
    }

    return SearchOutcome(
      bestMove: bestMove,
      score: bestScore,
      depth: completedDepth,
      principalVariation: pv,
      nodes: _nodes,
    );
  }

  /// Scores every legal root move with a full-window search of [depth]
  /// plies. Slower than [search] but gives exact scores for every move,
  /// which the weaker skill levels use to pick "human" mistakes.
  ///
  /// When [quiescence] is false, leaf positions are scored statically,
  /// so the engine overlooks recaptures like a beginner would.
  List<ScoredMove> scoreRootMoves(int depth, {bool quiescence = true}) {
    _prepare(null);
    final result = <ScoredMove>[];
    for (final move in board.legalMoves()) {
      board.makeMove(move);
      int score;
      if (!board.hasLegalMove()) {
        score = board.inCheck ? SearchScore.mate - 1 : 0;
      } else if (depth <= 1) {
        score = quiescence
            ? -_quiesce(-SearchScore.infinity, SearchScore.infinity, 1)
            : -Evaluator.evaluate(board);
      } else {
        score = -_negamax(
          depth - 1,
          -SearchScore.infinity,
          SearchScore.infinity,
          1,
          allowNull: true,
        );
      }
      board.unmakeMove();
      result.add(ScoredMove(move, score));
    }
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }

  /// Number of nodes visited by the last search.
  int get nodes => _nodes;

  void _prepare(int? timeLimitMs) {
    _nodes = 0;
    _stopped = false;
    _canStop = false;
    _timeLimitMs = timeLimitMs ?? 0;
    _killers.fillRange(0, _killers.length, 0);
    for (var i = 0; i < _history.length; i++) {
      _history[i] >>= 2;
    }
    _clock
      ..reset()
      ..start();
  }

  bool _checkTime() {
    if (_timeLimitMs > 0 &&
        _canStop &&
        (_nodes & 1023) == 0 &&
        _clock.elapsedMilliseconds >= _timeLimitMs) {
      _stopped = true;
    }
    return _stopped;
  }

  int _negamax(
    int depth,
    int alpha,
    int beta,
    int ply, {
    required bool allowNull,
  }) {
    _pvLength[ply] = ply;
    if (_checkTime()) return 0;

    if (ply > 0) {
      if (board.halfmoveClock >= 100 || board.isRepetition()) return 0;
      // Mate distance pruning.
      final mateAlpha = -SearchScore.mate + ply;
      final mateBeta = SearchScore.mate - ply - 1;
      if (alpha < mateAlpha) alpha = mateAlpha;
      if (beta > mateBeta) beta = mateBeta;
      if (alpha >= beta) return alpha;
    }

    final inCheck = board.inCheck;
    if (inCheck) depth++;
    if (depth <= 0 || ply >= maxPly - 2) return _quiesce(alpha, beta, ply);

    _nodes++;
    final isPvNode = beta - alpha > 1;

    var ttMove = 0;
    final slot = _table.probe(board.hashLo, board.hashHi);
    if (slot >= 0) {
      ttMove = _table.moveAt(slot);
      if (!isPvNode && ply > 0 && _table.depthAt(slot) >= depth) {
        final score = _fromTable(_table.scoreAt(slot), ply);
        final bound = _table.boundAt(slot);
        if (bound == TTBound.exact ||
            (bound == TTBound.lower && score >= beta) ||
            (bound == TTBound.upper && score <= alpha)) {
          return score;
        }
      }
    }

    // Null-move pruning: if passing still fails high, the position is so
    // good that a full search is unnecessary.
    if (allowNull &&
        !isPvNode &&
        !inCheck &&
        depth >= 3 &&
        board.hasNonPawnMaterial(board.turn) &&
        Evaluator.evaluate(board) >= beta) {
      board.makeNullMove();
      final reduction = depth > 6 ? 3 : 2;
      final score = -_negamax(
        depth - 1 - reduction,
        -beta,
        -beta + 1,
        ply + 1,
        allowNull: false,
      );
      board.unmakeNullMove();
      if (_stopped) return 0;
      if (score >= beta && !SearchScore.isMate(score)) return beta;
    }

    final start = ply * _movesPerPly;
    final end = board.generatePseudoMoves(_moves, start);
    _scoreMoves(start, end, ttMove, ply);

    final originalAlpha = alpha;
    var bestScore = -SearchScore.infinity;
    var bestMove = 0;
    var legalCount = 0;

    for (var i = start; i < end; i++) {
      final move = _pickNext(i, end);
      board.makeMove(move);
      if (board.isKingAttacked(-board.turn)) {
        board.unmakeMove();
        continue;
      }
      legalCount++;
      final givesCheck = board.inCheck;

      int score;
      if (legalCount == 1) {
        score = -_negamax(depth - 1, -beta, -alpha, ply + 1, allowNull: true);
      } else {
        var reduction = 0;
        if (depth >= 3 &&
            legalCount > 3 &&
            !inCheck &&
            !givesCheck &&
            MoveBits.isQuiet(move) &&
            move != _killers[ply * 2] &&
            move != _killers[ply * 2 + 1]) {
          reduction = legalCount > 8 ? 2 : 1;
        }
        score = -_negamax(
          depth - 1 - reduction,
          -alpha - 1,
          -alpha,
          ply + 1,
          allowNull: true,
        );
        if (score > alpha && reduction > 0) {
          score = -_negamax(
            depth - 1,
            -alpha - 1,
            -alpha,
            ply + 1,
            allowNull: true,
          );
        }
        if (score > alpha && score < beta) {
          score = -_negamax(depth - 1, -beta, -alpha, ply + 1, allowNull: true);
        }
      }
      board.unmakeMove();
      if (_stopped) return 0;

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
        if (score > alpha) {
          alpha = score;
          _updatePv(ply, move);
          if (score >= beta) {
            if (MoveBits.isQuiet(move)) _rememberQuietCutoff(move, ply, depth);
            break;
          }
        }
      }
    }

    if (legalCount == 0) {
      return inCheck ? -SearchScore.mate + ply : 0;
    }

    final bound = bestScore >= beta
        ? TTBound.lower
        : bestScore > originalAlpha
        ? TTBound.exact
        : TTBound.upper;
    _table.store(
      board.hashLo,
      board.hashHi,
      depth: depth,
      score: _toTable(bestScore, ply),
      bound: bound,
      move: bestMove,
    );
    return bestScore;
  }

  int _quiesce(int alpha, int beta, int ply) {
    _pvLength[ply] = ply;
    _nodes++;
    if (_checkTime()) return 0;

    final standPat = Evaluator.evaluate(board);
    if (ply >= maxPly - 1) return standPat;
    if (standPat >= beta) return standPat;
    if (standPat > alpha) alpha = standPat;

    final start = ply * _movesPerPly;
    final end = board.generatePseudoMoves(_moves, start, tacticalOnly: true);
    _scoreMoves(start, end, 0, ply);

    var best = standPat;
    for (var i = start; i < end; i++) {
      final move = _pickNext(i, end);
      // Delta pruning: skip captures that cannot raise alpha.
      if (MoveBits.promotion(move) == 0) {
        final victim = board.squares[MoveBits.to(move)].abs();
        final gain = victim == 0 ? 100 : Board.pieceValues[victim];
        if (standPat + gain + 200 < alpha) continue;
      }
      board.makeMove(move);
      if (board.isKingAttacked(-board.turn)) {
        board.unmakeMove();
        continue;
      }
      final score = -_quiesce(-beta, -alpha, ply + 1);
      board.unmakeMove();
      if (_stopped) return 0;
      if (score > best) {
        best = score;
        if (score > alpha) {
          alpha = score;
          _updatePv(ply, move);
          if (score >= beta) return score;
        }
      }
    }
    return best;
  }

  void _updatePv(int ply, int move) {
    final row = ply * maxPly;
    _pvTable[row + ply] = move;
    final childRow = (ply + 1) * maxPly;
    final childLength = ply + 1 < maxPly ? _pvLength[ply + 1] : ply + 1;
    for (var i = ply + 1; i < childLength; i++) {
      _pvTable[row + i] = _pvTable[childRow + i];
    }
    _pvLength[ply] = childLength > ply + 1 ? childLength : ply + 1;
  }

  void _rememberQuietCutoff(int move, int ply, int depth) {
    final k = ply * 2;
    if (_killers[k] != move) {
      _killers[k + 1] = _killers[k];
      _killers[k] = move;
    }
    final from = MoveBits.from(move);
    final piece = board.squares[from];
    final index = (piece + 6) * 128 + MoveBits.to(move);
    _history[index] += depth * depth;
    if (_history[index] > 400000) {
      for (var i = 0; i < _history.length; i++) {
        _history[i] >>= 1;
      }
    }
  }

  void _scoreMoves(int start, int end, int ttMove, int ply) {
    final squares = board.squares;
    final killer1 = _killers[ply * 2];
    final killer2 = _killers[ply * 2 + 1];
    for (var i = start; i < end; i++) {
      final move = _moves[i];
      int score;
      if (move == ttMove) {
        score = 2000000;
      } else if (MoveBits.isCapture(move)) {
        final victim = squares[MoveBits.to(move)].abs();
        final attacker = squares[MoveBits.from(move)].abs();
        score = 1000000 + (victim == 0 ? 1 : victim) * 10 - attacker;
      } else if (MoveBits.promotion(move) == 5) {
        score = 950000;
      } else if (move == killer1) {
        score = 900000;
      } else if (move == killer2) {
        score = 800000;
      } else {
        final piece = squares[MoveBits.from(move)];
        score = _history[(piece + 6) * 128 + MoveBits.to(move)];
      }
      _orderScores[i] = score;
    }
  }

  /// Selection sort step: moves the best remaining move to index [i].
  int _pickNext(int i, int end) {
    var best = i;
    var bestScore = _orderScores[i];
    for (var j = i + 1; j < end; j++) {
      if (_orderScores[j] > bestScore) {
        best = j;
        bestScore = _orderScores[j];
      }
    }
    if (best != i) {
      final move = _moves[best];
      _moves[best] = _moves[i];
      _moves[i] = move;
      _orderScores[best] = _orderScores[i];
      _orderScores[i] = bestScore;
    }
    return _moves[i];
  }

  static int _toTable(int score, int ply) {
    if (score >= SearchScore.mateThreshold) return score + ply;
    if (score <= -SearchScore.mateThreshold) return score - ply;
    return score;
  }

  static int _fromTable(int score, int ply) {
    if (score >= SearchScore.mateThreshold) return score - ply;
    if (score <= -SearchScore.mateThreshold) return score + ply;
    return score;
  }
}
