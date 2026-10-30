import 'package:chess_game/engine/chess_engine.dart';
import 'package:chess_game/features/game/domain/chess_clock.dart';
import 'package:chess_game/features/game/domain/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clock runs, adds increment and flags', () {
    var now = 0;
    final clock = ChessClock(const TimeControl(1, 2), timeSource: () => now);
    expect(clock.remaining(PieceColor.white), const Duration(minutes: 1));

    clock.start(PieceColor.white);
    now = 10000;
    expect(clock.remaining(PieceColor.white), const Duration(seconds: 50));

    clock.press(); // white moved: +2 s increment, black's clock starts.
    expect(clock.running, PieceColor.black);
    expect(clock.remaining(PieceColor.white), const Duration(seconds: 52));

    now += 61000;
    expect(clock.isFlagged(PieceColor.black), isTrue);
    expect(clock.remaining(PieceColor.black), Duration.zero);

    clock.pause();
    expect(clock.running, isNull);
  });
}
