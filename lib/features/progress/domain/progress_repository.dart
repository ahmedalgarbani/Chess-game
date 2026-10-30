import 'player_progress.dart';

/// Persists [PlayerProgress].
abstract interface class ProgressRepository {
  PlayerProgress load();

  Future<void> save(PlayerProgress progress);

  Future<void> clear();
}
