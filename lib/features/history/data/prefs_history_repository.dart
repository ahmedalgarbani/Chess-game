import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../game/domain/game_snapshot.dart';
import '../domain/game_record.dart';
import '../domain/history_repository.dart';

/// Stores the game history as JSON in shared preferences.
class PrefsHistoryRepository implements HistoryRepository {
  PrefsHistoryRepository(this._prefs);

  static const _gamesKey = 'history.games.v1';
  static const _unfinishedKey = 'history.unfinished.v1';

  final SharedPreferences _prefs;

  @override
  List<GameRecord> loadGames() {
    final decoded = _decode(_gamesKey);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map<String, Object?>) ?GameRecord.fromJson(entry),
    ];
  }

  @override
  Future<void> saveGames(List<GameRecord> games) => _prefs.setString(
    _gamesKey,
    jsonEncode([for (final game in games) game.toJson()]),
  );

  @override
  GameSnapshot? loadUnfinished() {
    final decoded = _decode(_unfinishedKey);
    return decoded is Map<String, Object?>
        ? GameSnapshot.fromJson(decoded)
        : null;
  }

  @override
  Future<void> saveUnfinished(GameSnapshot? game) => game == null
      ? _prefs.remove(_unfinishedKey)
      : _prefs.setString(_unfinishedKey, jsonEncode(game.toJson()));

  @override
  Future<void> clear() async {
    await _prefs.remove(_gamesKey);
    await _prefs.remove(_unfinishedKey);
  }

  Object? _decode(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
