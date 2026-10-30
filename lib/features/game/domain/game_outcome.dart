import '../../../engine/chess_engine.dart';

enum OutcomeReason {
  checkmate,
  stalemate,
  insufficientMaterial,
  fiftyMoveRule,
  threefoldRepetition,
  resignation,
  timeout,
  agreement,
  opponentLeft,
}

/// How a game ended. [winner] is null for draws.
class GameOutcome {
  const GameOutcome({required this.reason, this.winner});

  final OutcomeReason reason;
  final PieceColor? winner;

  bool get isDraw => winner == null;

  static GameOutcome? fromStatus(GameStatus status, PieceColor sideToMove) =>
      switch (status) {
        GameStatus.ongoing => null,
        GameStatus.checkmate => GameOutcome(
          reason: OutcomeReason.checkmate,
          winner: sideToMove.opposite,
        ),
        GameStatus.stalemate => const GameOutcome(
          reason: OutcomeReason.stalemate,
        ),
        GameStatus.insufficientMaterial => const GameOutcome(
          reason: OutcomeReason.insufficientMaterial,
        ),
        GameStatus.fiftyMoveRule => const GameOutcome(
          reason: OutcomeReason.fiftyMoveRule,
        ),
        GameStatus.threefoldRepetition => const GameOutcome(
          reason: OutcomeReason.threefoldRepetition,
        ),
      };
}
