import '../../../engine/chess_engine.dart';
import 'ai_level.dart';
import 'game_config.dart';

/// An unfinished game that can be continued later. Network games are never
/// saved, so the configuration has no connection.
class GameSnapshot {
  const GameSnapshot({
    required this.config,
    required this.moves,
    required this.savedAt,
    this.whiteTime,
    this.blackTime,
    this.hintsUsed = 0,
    this.undosUsed = 0,
  });

  final GameConfig config;

  /// The moves played so far, in UCI notation.
  final List<String> moves;
  final DateTime savedAt;

  /// Clock times left; null for untimed games.
  final Duration? whiteTime;
  final Duration? blackTime;
  final int hintsUsed;
  final int undosUsed;

  Map<String, Object?> toJson() => {
    'mode': config.mode.name,
    'playerColor': config.playerColor.name,
    'aiLevel': config.aiLevel?.number,
    'minutes': config.timeControl?.minutes,
    'increment': config.timeControl?.incrementSeconds,
    'whiteName': config.whiteName,
    'blackName': config.blackName,
    'ladder': config.ladder,
    'moves': moves,
    'savedAt': savedAt.toIso8601String(),
    'whiteMs': whiteTime?.inMilliseconds,
    'blackMs': blackTime?.inMilliseconds,
    'hintsUsed': hintsUsed,
    'undosUsed': undosUsed,
  };

  /// Returns null when [json] is not a valid saved game.
  static GameSnapshot? fromJson(Map<String, Object?> json) {
    final mode = GameMode.values.asNameMap()[json['mode']];
    final moves = json['moves'];
    final savedAt = DateTime.tryParse('${json['savedAt']}');
    if (mode == null || mode == GameMode.lan || moves is! List) return null;
    if (savedAt == null) return null;
    final level = json['aiLevel'];
    final minutes = json['minutes'];
    Duration? time(String key) => switch (json[key]) {
      final int ms => Duration(milliseconds: ms),
      _ => null,
    };
    return GameSnapshot(
      config: GameConfig(
        mode: mode,
        playerColor:
            PieceColor.values.asNameMap()[json['playerColor']] ??
            PieceColor.white,
        aiLevel: level is int ? AiLevel.byNumber(level) : null,
        timeControl: minutes is int
            ? TimeControl(minutes, json['increment'] as int? ?? 0)
            : null,
        whiteName: json['whiteName'] as String?,
        blackName: json['blackName'] as String?,
        ladder: json['ladder'] as bool? ?? false,
      ),
      moves: moves.whereType<String>().toList(),
      savedAt: savedAt,
      whiteTime: time('whiteMs'),
      blackTime: time('blackMs'),
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      undosUsed: json['undosUsed'] as int? ?? 0,
    );
  }
}
