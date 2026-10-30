import '../../../engine/chess_ai.dart';

/// A position described by its starting FEN and the moves played since.
/// This is cheap to send to a background isolate.
class PositionSnapshot {
  const PositionSnapshot(this.startFen, this.moves);

  final String startFen;
  final List<String> moves;

  PositionSnapshot withMove(String uci) =>
      PositionSnapshot(startFen, [...moves, uci]);
}

/// How much effort an analysis may spend.
enum AnalysisStrength {
  quick(6, 250),
  normal(10, 700),
  deep(16, 1500);

  const AnalysisStrength(this.maxDepth, this.timeLimitMs);

  final int maxDepth;
  final int timeLimitMs;
}

/// Runs the chess engine without blocking the UI.
abstract interface class ChessAiService {
  Future<EngineMove?> chooseMove(PositionSnapshot position, EngineSkill skill);

  Future<PositionAnalysis> analyze(
    PositionSnapshot position, {
    AnalysisStrength strength = AnalysisStrength.normal,
  });

  Future<MoveReview> reviewMove(PositionSnapshot position, String uci);
}
