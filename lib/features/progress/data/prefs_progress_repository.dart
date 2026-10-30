import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/player_progress.dart';
import '../domain/progress_repository.dart';

/// Stores progress as JSON in shared preferences.
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository(this._prefs);

  static const _key = 'progress.v1';

  final SharedPreferences _prefs;

  @override
  PlayerProgress load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const PlayerProgress();
    try {
      return PlayerProgress.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const PlayerProgress();
    }
  }

  @override
  Future<void> save(PlayerProgress progress) =>
      _prefs.setString(_key, jsonEncode(progress.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}
