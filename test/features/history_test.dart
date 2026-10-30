import 'package:chess_game/engine/chess_engine.dart';
import 'package:chess_game/features/game/domain/ai_level.dart';
import 'package:chess_game/features/game/domain/game_config.dart';
import 'package:chess_game/features/game/domain/game_outcome.dart';
import 'package:chess_game/features/game/domain/game_snapshot.dart';
import 'package:chess_game/features/history/domain/game_record.dart';
import 'package:chess_game/features/history/domain/game_replay.dart';
import 'package:chess_game/features/history/domain/history_repository.dart';
import 'package:chess_game/features/history/presentation/history_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryHistoryRepository implements HistoryRepository {
  List<GameRecord> games = [];
  GameSnapshot? unfinished;

  @override
  List<GameRecord> loadGames() => games;

  @override
  Future<void> saveGames(List<GameRecord> games) async => this.games = games;

  @override
  GameSnapshot? loadUnfinished() => unfinished;

  @override
  Future<void> saveUnfinished(GameSnapshot? game) async => unfinished = game;

  @override
  Future<void> clear() async {
    games = [];
    unfinished = null;
  }
}

GameRecord record(int minute, {PieceColor? winner = PieceColor.white}) =>
    GameRecord.finished(
      config: GameConfig(
        mode: GameMode.computer,
        aiLevel: AiLevel.byNumber(4),
        whiteName: 'Sara',
        blackName: 'Computer',
      ),
      moves: const ['f2f3', 'e7e5', 'g2g4', 'd8h4'],
      outcome: GameOutcome(reason: OutcomeReason.checkmate, winner: winner),
      playedAt: DateTime(2026, 10, 1, 12, minute),
      whiteName: 'Sara',
      blackName: 'Computer',
    );

void main() {
  test('a game record survives a JSON round trip', () {
    final original = record(5, winner: PieceColor.black);
    final restored = GameRecord.fromJson(original.toJson())!;
    expect(restored.playedAt, original.playedAt);
    expect(restored.moves, original.moves);
    expect(restored.winner, PieceColor.black);
    expect(restored.reason, OutcomeReason.checkmate);
    expect(restored.aiLevel, 4);
    expect(restored.opponentName, 'Computer');
    expect(restored.playerWon, isFalse);
    expect(GameRecord.fromJson(const {'mode': 'chess'}), isNull);
  });

  test('a saved game survives a JSON round trip', () {
    final original = GameSnapshot(
      config: GameConfig(
        mode: GameMode.computer,
        playerColor: PieceColor.black,
        aiLevel: AiLevel.byNumber(3),
        timeControl: const TimeControl(5, 3),
        whiteName: 'Computer',
        blackName: 'Sara',
        ladder: true,
      ),
      moves: const ['e2e4', 'c7c5'],
      savedAt: DateTime(2026, 10, 2),
      whiteTime: const Duration(seconds: 250),
      blackTime: const Duration(seconds: 280),
      hintsUsed: 2,
      undosUsed: 1,
    );
    final restored = GameSnapshot.fromJson(original.toJson())!;
    expect(restored.config.mode, GameMode.computer);
    expect(restored.config.playerColor, PieceColor.black);
    expect(restored.config.aiLevel?.number, 3);
    expect(restored.config.timeControl, const TimeControl(5, 3));
    expect(restored.config.ladder, isTrue);
    expect(restored.moves, original.moves);
    expect(restored.whiteTime, original.whiteTime);
    expect(restored.blackTime, original.blackTime);
    expect(restored.hintsUsed, 2);
    expect(restored.undosUsed, 1);
    expect(GameSnapshot.fromJson(const {'mode': 'lan', 'moves': []}), isNull);
  });

  test('the history keeps the newest games and ends the unfinished one', () {
    final repository = MemoryHistoryRepository();
    final cubit = HistoryCubit(repository);
    cubit.saveUnfinished(
      GameSnapshot(
        config: const GameConfig(mode: GameMode.local),
        moves: const ['e2e4'],
        savedAt: DateTime(2026),
      ),
    );
    expect(repository.unfinished, isNotNull);
    for (var i = 0; i < HistoryCubit.maxGames + 5; i++) {
      cubit.record(record(i));
    }
    expect(cubit.state.games, hasLength(HistoryCubit.maxGames));
    expect(cubit.state.games.first.playedAt.minute, HistoryCubit.maxGames + 4);
    expect(cubit.state.unfinished, isNull);
    expect(repository.unfinished, isNull);
    expect(repository.games, hasLength(HistoryCubit.maxGames));
  });

  test('a replay steps through every position', () {
    final replay = GameReplay(const ['f2f3', 'e7e5', 'g2g4', 'd8h4']);
    expect(replay.length, 4);
    expect(replay.sans, ['f3', 'e5', 'g4', 'Qh4#']);
    expect(replay.positions, hasLength(5));
    expect(replay.checks.last, Square.parse('e1'));
    expect(replay.uciUpTo(2), ['f2f3', 'e7e5']);
    expect(GameReplay(const ['e2e4', 'e2e4']).length, 1);
  });

  test('a finished network game keeps the saved game', () {
    final repository = MemoryHistoryRepository();
    final cubit = HistoryCubit(repository);
    final saved = GameSnapshot(
      config: const GameConfig(mode: GameMode.local),
      moves: const ['e2e4'],
      savedAt: DateTime(2026),
    );
    cubit.saveUnfinished(saved);
    cubit.record(
      GameRecord.finished(
        config: const GameConfig(mode: GameMode.lan),
        moves: const ['d2d4'],
        outcome: const GameOutcome(reason: OutcomeReason.agreement),
        playedAt: DateTime(2026, 2),
        whiteName: 'Sara',
        blackName: 'Ali',
      ),
    );
    expect(cubit.state.unfinished, same(saved));
    expect(repository.unfinished, same(saved));
    expect(cubit.state.games, hasLength(1));
  });
}
