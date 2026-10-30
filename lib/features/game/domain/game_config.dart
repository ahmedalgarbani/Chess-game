import '../../../engine/chess_engine.dart';
import '../../lan/domain/lan_connection.dart';
import 'ai_level.dart';

enum GameMode { computer, local, lan }

/// A chess clock setting such as "3 + 2" (minutes + seconds increment).
class TimeControl {
  const TimeControl(this.minutes, [this.incrementSeconds = 0]);

  final int minutes;
  final int incrementSeconds;

  Duration get initial => Duration(minutes: minutes);

  Duration get increment => Duration(seconds: incrementSeconds);

  /// Short label like `5` or `3+2`.
  String get label =>
      incrementSeconds == 0 ? '$minutes' : '$minutes+$incrementSeconds';

  static const presets = <TimeControl>[
    TimeControl(1),
    TimeControl(3, 2),
    TimeControl(5),
    TimeControl(10),
    TimeControl(15, 10),
    TimeControl(30),
  ];

  @override
  bool operator ==(Object other) =>
      other is TimeControl &&
      other.minutes == minutes &&
      other.incrementSeconds == incrementSeconds;

  @override
  int get hashCode => Object.hash(minutes, incrementSeconds);
}

/// Everything needed to start a game.
class GameConfig {
  const GameConfig({
    required this.mode,
    this.playerColor = PieceColor.white,
    this.aiLevel,
    this.timeControl,
    this.whiteName,
    this.blackName,
    this.lanConnection,
    this.ladder = false,
  });

  final GameMode mode;

  /// The local player's colour (for local games: the side at the bottom).
  final PieceColor playerColor;
  final AiLevel? aiLevel;

  /// Null means no clock.
  final TimeControl? timeControl;
  final String? whiteName;
  final String? blackName;
  final LanConnection? lanConnection;

  /// Whether this game is part of the computer levels journey.
  final bool ladder;

  /// Whether moves for [color] are entered on this device.
  bool controlsColor(PieceColor color) =>
      mode == GameMode.local || color == playerColor;

  /// The same game with the colours swapped, used for rematches.
  GameConfig swapColors() => GameConfig(
    mode: mode,
    playerColor: playerColor.opposite,
    aiLevel: aiLevel,
    timeControl: timeControl,
    whiteName: blackName,
    blackName: whiteName,
    lanConnection: lanConnection,
    ladder: ladder,
  );
}
