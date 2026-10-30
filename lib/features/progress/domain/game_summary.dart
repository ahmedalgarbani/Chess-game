/// Where a finished game was played.
enum PlayedMode { computer, local, lan }

/// The outcome of a game from the local player's point of view.
enum PlayerResult { win, draw, loss }

/// Everything the reward rules need to know about a finished game.
class GameSummary {
  const GameSummary({
    required this.mode,
    required this.result,
    this.aiLevel,
    this.byCheckmate = false,
    this.playerMoves = 0,
    this.hintsUsed = 0,
    this.undosUsed = 0,
    this.castled = false,
    this.promoted = false,
    this.enPassant = false,
  });

  final PlayedMode mode;

  /// Null for games between two people on the same device.
  final PlayerResult? result;

  /// The computer level (1–10) for games against the computer.
  final int? aiLevel;
  final bool byCheckmate;
  final int playerMoves;
  final int hintsUsed;
  final int undosUsed;
  final bool castled;
  final bool promoted;
  final bool enPassant;
}
