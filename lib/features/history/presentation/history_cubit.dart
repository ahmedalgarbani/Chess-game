import 'package:flutter_bloc/flutter_bloc.dart';

import '../../game/domain/game_config.dart';
import '../../game/domain/game_snapshot.dart';
import '../domain/game_record.dart';
import '../domain/history_repository.dart';

/// Finished games (newest first) and the game waiting to be resumed.
class GameArchive {
  const GameArchive({this.games = const [], this.unfinished});

  final List<GameRecord> games;
  final GameSnapshot? unfinished;
}

/// Keeps the game history and the unfinished game.
class HistoryCubit extends Cubit<GameArchive> {
  HistoryCubit(this._repository)
    : super(
        GameArchive(
          games: _repository.loadGames(),
          unfinished: _repository.loadUnfinished(),
        ),
      );

  /// How many finished games are kept.
  static const int maxGames = 30;

  final HistoryRepository _repository;

  /// Adds a finished game, which is then no longer resumable. Network
  /// games are never saved for later, so they leave the unfinished game.
  void record(GameRecord game) {
    final games = [game, ...state.games].take(maxGames).toList();
    final unfinished = game.mode == GameMode.lan ? state.unfinished : null;
    emit(GameArchive(games: games, unfinished: unfinished));
    _repository.saveGames(games);
    if (unfinished == null) _repository.saveUnfinished(null);
  }

  /// Remembers the game in progress so it can be resumed.
  void saveUnfinished(GameSnapshot game) {
    emit(GameArchive(games: state.games, unfinished: game));
    _repository.saveUnfinished(game);
  }

  void discardUnfinished() {
    if (state.unfinished == null) return;
    emit(GameArchive(games: state.games));
    _repository.saveUnfinished(null);
  }

  Future<void> clear() async {
    await _repository.clear();
    emit(const GameArchive());
  }
}
