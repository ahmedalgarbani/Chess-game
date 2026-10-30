import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../engine/chess_ai.dart';
import '../domain/chess_ai_service.dart';

/// Runs the engine in a background isolate via [compute], so searching
/// never blocks the UI thread (on the web it runs on the main thread).
class IsolateChessAiService implements ChessAiService {
  IsolateChessAiService({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Future<EngineMove?> chooseMove(PositionSnapshot position, EngineSkill skill) {
    return compute(
      _chooseMove,
      _MoveRequest(
        position.startFen,
        position.moves,
        skill,
        _random.nextInt(1 << 30),
      ),
    );
  }

  @override
  Future<PositionAnalysis> analyze(
    PositionSnapshot position, {
    AnalysisStrength strength = AnalysisStrength.normal,
  }) {
    return compute(
      _analyze,
      _AnalysisRequest(
        position.startFen,
        position.moves,
        strength.maxDepth,
        strength.timeLimitMs,
      ),
    );
  }

  @override
  Future<MoveReview> reviewMove(PositionSnapshot position, String uci) {
    return compute(
      _reviewMove,
      _ReviewRequest(position.startFen, position.moves, uci),
    );
  }
}

class _MoveRequest {
  const _MoveRequest(this.fen, this.moves, this.skill, this.seed);

  final String fen;
  final List<String> moves;
  final EngineSkill skill;
  final int seed;
}

class _AnalysisRequest {
  const _AnalysisRequest(this.fen, this.moves, this.maxDepth, this.timeLimitMs);

  final String fen;
  final List<String> moves;
  final int maxDepth;
  final int timeLimitMs;
}

class _ReviewRequest {
  const _ReviewRequest(this.fen, this.moves, this.uci);

  final String fen;
  final List<String> moves;
  final String uci;
}

EngineMove? _chooseMove(_MoveRequest request) {
  final board = ChessAi.replay(request.fen, request.moves);
  return ChessAi.chooseMove(board, request.skill, random: Random(request.seed));
}

PositionAnalysis _analyze(_AnalysisRequest request) {
  final board = ChessAi.replay(request.fen, request.moves);
  return ChessAi.analyze(
    board,
    maxDepth: request.maxDepth,
    timeLimitMs: request.timeLimitMs,
  );
}

MoveReview _reviewMove(_ReviewRequest request) {
  final board = ChessAi.replay(request.fen, request.moves);
  final move = board.findMove(request.uci);
  if (move == null) {
    return const MoveReview(
      lossCp: 0,
      bestMove: null,
      refutation: null,
      allowsMate: false,
    );
  }
  return ChessAi.reviewMove(board, move);
}
