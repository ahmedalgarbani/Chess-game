import 'achievement.dart';
import 'player_rank.dart';

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
    this.ownedBoardThemes = const {'royal', 'midnight'},
    this.ownedPieceStyles = const {'royal', 'classic'},
    this.completedLessons = const {},
    this.stats = const GameStats(),
    this.dailyStreak = 0,
    this.lastDailyClaim,
  });

  static const int computerLevels = 10;

  final int xp;
  final int coins;

  /// Best star rating (1–3) for every computer level beaten.
  final Map<int, int> levelStars;
  final Set<Achievement> achievements;
  final Set<String> ownedBoardThemes;
  final Set<String> ownedPieceStyles;
  final Set<String> completedLessons;
  final GameStats stats;
  final int dailyStreak;

  /// Calendar day (local time) of the last daily reward claim.
  final DateTime? lastDailyClaim;

  int get level => PlayerRank.levelForXp(xp);

  RankTitle get title => PlayerRank.titleFor(level);

  int get totalStars => levelStars.values.fold(0, (sum, s) => sum + s);

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

  static DateTime _day(DateTime time) =>
      DateTime(time.year, time.month, time.day);

  PlayerProgress copyWith({
    int? xp,
    int? coins,
    Map<int, int>? levelStars,
    Set<Achievement>? achievements,
    Set<String>? ownedBoardThemes,
    Set<String>? ownedPieceStyles,
    Set<String>? completedLessons,
    GameStats? stats,
    int? dailyStreak,
    DateTime? lastDailyClaim,
  }) {
    return PlayerProgress(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      levelStars: levelStars ?? this.levelStars,
      achievements: achievements ?? this.achievements,
      ownedBoardThemes: ownedBoardThemes ?? this.ownedBoardThemes,
      ownedPieceStyles: ownedPieceStyles ?? this.ownedPieceStyles,
      completedLessons: completedLessons ?? this.completedLessons,
      stats: stats ?? this.stats,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
    );
  }

  Map<String, Object?> toJson() => {
    'xp': xp,
    'coins': coins,
    'levelStars': {for (final e in levelStars.entries) '${e.key}': e.value},
    'achievements': [for (final a in achievements) a.name],
    'ownedBoardThemes': ownedBoardThemes.toList(),
    'ownedPieceStyles': ownedPieceStyles.toList(),
    'completedLessons': completedLessons.toList(),
    'stats': stats.toJson(),
    'dailyStreak': dailyStreak,
    'lastDailyClaim': lastDailyClaim?.toIso8601String(),
  };

  factory PlayerProgress.fromJson(Map<String, Object?> json) {
    const defaults = PlayerProgress();
    Set<String> strings(String key, Set<String> fallback) {
      final value = json[key];
      return value is List
          ? {...fallback, ...value.whereType<String>()}
          : fallback;
    }

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
    final rawAchievements = json['achievements'];
    final stats = json['stats'];
    final lastClaim = json['lastDailyClaim'];
    return PlayerProgress(
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? defaults.coins,
      levelStars: stars,
      achievements: {
        if (rawAchievements is List)
          for (final name in rawAchievements.whereType<String>())
            ?Achievement.byName(name),
      },
      ownedBoardThemes: strings('ownedBoardThemes', defaults.ownedBoardThemes),
      ownedPieceStyles: strings('ownedPieceStyles', defaults.ownedPieceStyles),
      completedLessons: strings('completedLessons', const {}),
      stats: stats is Map<String, Object?>
          ? GameStats.fromJson(stats)
          : const GameStats(),
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      lastDailyClaim: lastClaim is String ? DateTime.tryParse(lastClaim) : null,
    );
  }
}
