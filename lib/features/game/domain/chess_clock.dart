import '../../../engine/chess_engine.dart';
import 'game_config.dart';

/// Returns a monotonic timestamp in milliseconds.
typedef TimeSource = int Function();

/// A two-sided chess clock with Fischer increment.
class ChessClock {
  ChessClock(TimeControl control, {TimeSource? timeSource})
    : _increment = control.increment.inMilliseconds,
      _remaining = {
        PieceColor.white: control.initial.inMilliseconds,
        PieceColor.black: control.initial.inMilliseconds,
      },
      _now = timeSource ?? _defaultTimeSource;

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static int _defaultTimeSource() => _stopwatch.elapsedMilliseconds;

  final int _increment;
  final Map<PieceColor, int> _remaining;
  final TimeSource _now;

  PieceColor? _running;
  int _startedAt = 0;

  PieceColor? get running => _running;

  Duration remaining(PieceColor color) {
    var ms = _remaining[color]!;
    if (_running == color) ms -= _now() - _startedAt;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  bool isFlagged(PieceColor color) => remaining(color) == Duration.zero;

  /// Starts (or resumes) the clock of [color].
  void start(PieceColor color) {
    pause();
    _running = color;
    _startedAt = _now();
  }

  /// Ends the turn of the running side: adds the increment and starts the
  /// opponent's clock.
  void press() {
    final current = _running;
    if (current == null) return;
    pause();
    _remaining[current] = _remaining[current]! + _increment;
    start(current.opposite);
  }

  void pause() {
    final current = _running;
    if (current == null) return;
    _remaining[current] = remaining(current).inMilliseconds;
    _running = null;
  }

  /// Overrides a side's time (used to stay in sync with a network opponent).
  void setRemaining(PieceColor color, Duration time) {
    _remaining[color] = time.inMilliseconds;
    if (_running == color) _startedAt = _now();
  }
}
