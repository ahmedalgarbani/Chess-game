import 'achievement.dart';
import 'player_rank.dart';
import 'shop_items.dart';

/// Lifetime game counters.
class GameStats {
  const GameStats({
    this.played = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.checkmates = 0,
  });

  final int played;
  final int wins;
  final int losses;
  final int draws;
  final int checkmates;

  double get winRate => played == 0 ? 0 : wins / played;

  GameStats copyWith({
    int? played,
    int? wins,
    int? losses,
    int? draws,
    int? checkmates,
  }) => GameStats(
    played: played ?? this.played,
    wins: wins ?? this.wins,
    losses: losses ?? this.losses,
    draws: draws ?? this.draws,
    checkmates: checkmates ?? this.checkmates,
  );

  Map<String, Object?> toJson() => {
    'played': played,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'checkmates': checkmates,
  };

  factory GameStats.fromJson(Map<String, Object?> json) => GameStats(
    played: json['played'] as int? ?? 0,
    wins: json['wins'] as int? ?? 0,
    losses: json['losses'] as int? ?? 0,
    draws: json['draws'] as int? ?? 0,
    checkmates: json['checkmates'] as int? ?? 0,
  );
}

/// Experience, currency, unlocks and achievements of the player.
class PlayerProgress {
  const PlayerProgress({
    this.xp = 0,
    this.coins = 50,
    this.levelStars = const {},
    this.achievements = const {},
    this.owned = const {},
    this.completedLessons = const {},
    this.solvedPuzzles = const {},
    this.stats = const GameStats(),
    this.dailyStreak = 0,
    this.lastDailyClaim,
    this.lastDailyPuzzle,
    this.hintTokens = 0,
    this.xpBoostGames = 0,
    this.streakShields = 0,
  });

  static const int computerLevels = 10;

  final int xp;
  final int coins;

  /// Best star rating (1–3) for every computer level beaten.
  final Map<int, int> levelStars;
  final Set<Achievement> achievements;

  /// Purchased cosmetics per kind (starter items are always owned).
  final Map<CosmeticKind, Set<String>> owned;
  final Set<String> completedLessons;
  final Set<String> solvedPuzzles;
  final GameStats stats;
  final int dailyStreak;

  /// Calendar day (local time) of the last daily reward claim.
  final DateTime? lastDailyClaim;

  /// Calendar day the daily puzzle was last solved.
  final DateTime? lastDailyPuzzle;

  // Boosts.
  final int hintTokens;
  final int xpBoostGames;
  final int streakShields;

  int get level => PlayerRank.levelForXp(xp);

  RankTitle get title => PlayerRank.titleFor(level);

  int get totalStars => levelStars.values.fold(0, (sum, s) => sum + s);

  bool owns(CosmeticKind kind, String id) =>
      kind.starterItems.contains(id) || (owned[kind]?.contains(id) ?? false);

  /// Number of cosmetics bought in the shop.
  int get purchasedCount =>
      owned.values.fold(0, (sum, items) => sum + items.length);

  /// The highest computer level the player may challenge.
  int get highestUnlockedLevel {
    var level = 1;
    while (level < computerLevels && levelStars.containsKey(level)) {
      level++;
    }
    return level;
  }

  bool isLevelUnlocked(int level) => level <= highestUnlockedLevel;

  bool canClaimDaily(DateTime now) {
    final last = lastDailyClaim;
    return last == null || _day(now).isAfter(_day(last));
  }

  bool solvedDailyPuzzle(DateTime now) {
    final last = lastDailyPuzzle;
    return last != null && !_day(now).isAfter(_day(last));
  }

  static DateTime _day(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  PlayerProgress copyWith({
    int? xp,
    int? coins,
    Map<int, int>? levelStars,
    Set<Achievement>? achievements,
    Map<CosmeticKind, Set<String>>? owned,
    Set<String>? completedLessons,
    Set<String>? solvedPuzzles,
    GameStats? stats,
    int? dailyStreak,
    DateTime? lastDailyClaim,
    DateTime? lastDailyPuzzle,
    int? hintTokens,
    int? xpBoostGames,
    int? streakShields,
  }) {
    return PlayerProgress(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      levelStars: levelStars ?? this.levelStars,
      achievements: achievements ?? this.achievements,
      owned: owned ?? this.owned,
      completedLessons: completedLessons ?? this.completedLessons,
      solvedPuzzles: solvedPuzzles ?? this.solvedPuzzles,
      stats: stats ?? this.stats,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
      lastDailyPuzzle: lastDailyPuzzle ?? this.lastDailyPuzzle,
      hintTokens: hintTokens ?? this.hintTokens,
      xpBoostGames: xpBoostGames ?? this.xpBoostGames,
      streakShields: streakShields ?? this.streakShields,
    );
  }

  /// A copy that also owns [id] of [kind].
  PlayerProgress withOwned(CosmeticKind kind, String id) => copyWith(
    owned: {
      ...owned,
      kind: {...?owned[kind], id},
    },
  );

  Map<String, Object?> toJson() => {
    'xp': xp,
    'coins': coins,
    'levelStars': {for (final e in levelStars.entries) '${e.key}': e.value},
    'achievements': [for (final a in achievements) a.name],
    'owned': {for (final e in owned.entries) e.key.name: e.value.toList()},
    'completedLessons': completedLessons.toList(),
    'solvedPuzzles': solvedPuzzles.toList(),
    'stats': stats.toJson(),
    'dailyStreak': dailyStreak,
    'lastDailyClaim': lastDailyClaim?.toIso8601String(),
    'lastDailyPuzzle': lastDailyPuzzle?.toIso8601String(),
    'hintTokens': hintTokens,
    'xpBoostGames': xpBoostGames,
    'streakShields': streakShields,
  };

  factory PlayerProgress.fromJson(Map<String, Object?> json) {
    const defaults = PlayerProgress();
    Set<String> strings(Object? value) =>
        value is List ? value.whereType<String>().toSet() : <String>{};

    final stars = <int, int>{};
    final rawStars = json['levelStars'];
    if (rawStars is Map) {
      for (final entry in rawStars.entries) {
        final level = int.tryParse('${entry.key}');
        if (level != null && entry.value is int) {
          stars[level] = entry.value as int;
        }
      }
    }

    final owned = <CosmeticKind, Set<String>>{};
    final rawOwned = json['owned'];
    if (rawOwned is Map) {
      for (final entry in rawOwned.entries) {
        final kind = CosmeticKind.byName('${entry.key}');
        if (kind != null) owned[kind] = strings(entry.value);
      }
    }
    // Saves from version 1.0 kept boards and pieces in separate lists.
    for (final (key, kind) in const [
      ('ownedBoardThemes', CosmeticKind.board),
      ('ownedPieceStyles', CosmeticKind.pieces),
    ]) {
      final legacy = strings(json[key]).difference(kind.starterItems);
      if (legacy.isNotEmpty) owned[kind] = {...?owned[kind], ...legacy};
    }

    final rawAchievements = json['achievements'];
    final stats = json['stats'];
    DateTime? date(String key) {
      final value = json[key];
      return value is String ? DateTime.tryParse(value) : null;
    }

    int count(String key) => json[key] as int? ?? 0;

    return PlayerProgress(
      xp: count('xp'),
      coins: json['coins'] as int? ?? defaults.coins,
      levelStars: stars,
      achievements: {
        if (rawAchievements is List)
          for (final name in rawAchievements.whereType<String>())
            ?Achievement.byName(name),
      },
      owned: owned,
      completedLessons: strings(json['completedLessons']),
      solvedPuzzles: strings(json['solvedPuzzles']),
      stats: stats is Map<String, Object?>
          ? GameStats.fromJson(stats)
          : const GameStats(),
      dailyStreak: count('dailyStreak'),
      lastDailyClaim: date('lastDailyClaim'),
      lastDailyPuzzle: date('lastDailyPuzzle'),
      hintTokens: count('hintTokens'),
      xpBoostGames: count('xpBoostGames'),
      streakShields: count('streakShields'),
    );
  }
}
