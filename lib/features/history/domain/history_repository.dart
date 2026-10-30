import '../../game/domain/game_snapshot.dart';
import 'game_record.dart';

/// Persists finished games and the unfinished game that can be resumed.
abstract interface class HistoryRepository {
  List<GameRecord> loadGames();

  Future<void> saveGames(List<GameRecord> games);

  GameSnapshot? loadUnfinished();

  Future<void> saveUnfinished(GameSnapshot? game);

  Future<void> clear();
}
