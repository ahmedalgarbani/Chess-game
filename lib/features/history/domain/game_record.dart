import '../../../engine/chess_engine.dart';
import '../../game/domain/game_config.dart';
import '../../game/domain/game_outcome.dart';

/// A finished game kept for later review.
class GameRecord {
  const GameRecord({
    required this.playedAt,
    required this.mode,
    required this.playerColor,
    required this.whiteName,
    required this.blackName,
    required this.moves,
    required this.reason,
    this.winner,
    this.aiLevel,
  });

  /// Builds the record of a game that just ended.
  factory GameRecord.finished({
    required GameConfig config,
    required List<String> moves,
    required GameOutcome outcome,
    required DateTime playedAt,
    required String whiteName,
    required String blackName,
  }) => GameRecord(
    playedAt: playedAt,
    mode: config.mode,
    playerColor: config.playerColor,
    whiteName: whiteName,
    blackName: blackName,
    moves: List.unmodifiable(moves),
    reason: outcome.reason,
    winner: outcome.winner,
    aiLevel: config.aiLevel?.number,
  );

  final DateTime playedAt;
  final GameMode mode;

  /// The device owner's colour (the bottom side in pass-and-play games).
  final PieceColor playerColor;
  final String whiteName;
  final String blackName;

  /// The moves in UCI notation, from the standard starting position.
  final List<String> moves;
  final OutcomeReason reason;

  /// Null for draws.
  final PieceColor? winner;
  final int? aiLevel;

  /// The opponent's name from the device owner's point of view.
  String get opponentName =>
      playerColor == PieceColor.white ? blackName : whiteName;

  /// True or false for games with a single local player, null in
  /// pass-and-play games and for draws.
  bool? get playerWon =>
      mode == GameMode.local || winner == null ? null : winner == playerColor;

  Map<String, Object?> toJson() => {
    'playedAt': playedAt.toIso8601String(),
    'mode': mode.name,
    'playerColor': playerColor.name,
    'whiteName': whiteName,
    'blackName': blackName,
    'moves': moves,
    'reason': reason.name,
    'winner': winner?.name,
    'aiLevel': aiLevel,
  };

  /// Returns null when [json] is not a valid record.
  static GameRecord? fromJson(Map<String, Object?> json) {
    final playedAt = DateTime.tryParse('${json['playedAt']}');
    final mode = GameMode.values.asNameMap()[json['mode']];
    final reason = OutcomeReason.values.asNameMap()[json['reason']];
    final moves = json['moves'];
    if (playedAt == null || mode == null || reason == null || moves is! List) {
      return null;
    }
    final colors = PieceColor.values.asNameMap();
    return GameRecord(
      playedAt: playedAt,
      mode: mode,
      playerColor: colors[json['playerColor']] ?? PieceColor.white,
      whiteName: json['whiteName'] as String? ?? '',
      blackName: json['blackName'] as String? ?? '',
      moves: moves.whereType<String>().toList(),
      reason: reason,
      winner: colors[json['winner']],
      aiLevel: json['aiLevel'] as int?,
    );
  }
}
