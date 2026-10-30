import 'achievement.dart';
import 'game_summary.dart';
import 'player_progress.dart';

/// What the player earned from one finished game.
class GameRewards {
  const GameRewards({
    required this.xp,
    required this.coins,
    required this.levelBefore,
    required this.levelAfter,
    this.stars,
    this.newAchievements = const [],
    this.unlockedComputerLevel,
  });

  final int xp;

  /// Coins from the game itself plus any achievement payouts.
  final int coins;
  final int levelBefore;
  final int levelAfter;

  /// Star rating for a win against the computer.
  final int? stars;
  final List<Achievement> newAchievements;

  /// The computer level unlocked by this win, if any.
  final int? unlockedComputerLevel;

  bool get leveledUp => levelAfter > levelBefore;
}

/// The rules that turn games, lessons and daily visits into rewards.
abstract final class RewardRules {
  static const int lessonXp = 30;
  static const int lessonCoins = 15;

  /// Applies a finished game to [progress].
  static (PlayerProgress, GameRewards) applyGame(
    PlayerProgress progress,
    GameSummary game,
  ) {
    var xp = 0;
    var coins = 0;
    int? stars;
    int? unlocked;
    final levelStars = Map<int, int>.of(progress.levelStars);

    switch (game.mode) {
      case PlayedMode.computer:
        final level = game.aiLevel ?? 1;
        switch (game.result) {
          case PlayerResult.win:
            xp = 40 + 20 * level;
            coins = 10 + 5 * level;
            stars = starsFor(game);
            final previous = levelStars[level];
            if (previous == null) {
              coins += 20 + 10 * level;
              if (level < PlayerProgress.computerLevels) unlocked = level + 1;
            }
            if (previous == null || stars > previous) levelStars[level] = stars;
          case PlayerResult.draw:
            xp = 15 + 8 * level;
            coins = 5;
          case PlayerResult.loss || null:
            xp = 10;
        }
      case PlayedMode.local:
        xp = 20;
        coins = 5;
      case PlayedMode.lan:
        (xp, coins) = switch (game.result) {
          PlayerResult.win => (50, 15),
          PlayerResult.draw => (25, 5),
          PlayerResult.loss || null => (15, 0),
        };
    }

    final stats = progress.stats.copyWith(
      played: progress.stats.played + 1,
      wins: progress.stats.wins + (game.result == PlayerResult.win ? 1 : 0),
      losses:
          progress.stats.losses + (game.result == PlayerResult.loss ? 1 : 0),
      draws: progress.stats.draws + (game.result == PlayerResult.draw ? 1 : 0),
      checkmates:
          progress.stats.checkmates +
          (game.result == PlayerResult.win && game.byCheckmate ? 1 : 0),
    );

    var updated = progress.copyWith(
      xp: progress.xp + xp,
      coins: progress.coins + coins,
      levelStars: levelStars,
      stats: stats,
    );
    final earned = _gameAchievements(updated, game);
    updated = _grant(updated, earned);
    final achievementCoins = earned.fold(0, (sum, a) => sum + a.coins);

    return (
      updated,
      GameRewards(
        xp: xp,
        coins: coins + achievementCoins,
        levelBefore: progress.level,
        levelAfter: updated.level,
        stars: stars,
        newAchievements: earned,
        unlockedComputerLevel: unlocked,
      ),
    );
  }

  /// Star rating for a win: fewer hints and take-backs earn more stars.
  static int starsFor(GameSummary game) {
    if (game.hintsUsed == 0 && game.undosUsed == 0) return 3;
    if (game.hintsUsed <= 2 && game.undosUsed <= 1) return 2;
    return 1;
  }

  /// Marks a lesson as completed. Returns null if it was already completed.
  static (PlayerProgress, GameRewards)? applyLesson(
    PlayerProgress progress,
    String lessonId, {
    required int totalLessons,
  }) {
    if (progress.completedLessons.contains(lessonId)) return null;
    var updated = progress.copyWith(
      xp: progress.xp + lessonXp,
      coins: progress.coins + lessonCoins,
      completedLessons: {...progress.completedLessons, lessonId},
    );
    final earned = <Achievement>[
      if (updated.completedLessons.length >= totalLessons &&
          !updated.achievements.contains(Achievement.allLessons))
        Achievement.allLessons,
    ];
    updated = _grant(updated, earned);
    return (
      updated,
      GameRewards(
        xp: lessonXp,
        coins: lessonCoins + earned.fold(0, (sum, a) => sum + a.coins),
        levelBefore: progress.level,
        levelAfter: updated.level,
        newAchievements: earned,
      ),
    );
  }

  /// Coins for the daily reward with a streak of [streak] days.
  static int dailyCoins(int streak) => 20 + 10 * (streak.clamp(1, 7) - 1);

  /// Claims the daily reward. Returns null if it was already claimed today.
  static (PlayerProgress, int)? claimDaily(
    PlayerProgress progress,
    DateTime now,
  ) {
    if (!progress.canClaimDaily(now)) return null;
    final last = progress.lastDailyClaim;
    final today = DateTime(now.year, now.month, now.day);
    final continues =
        last != null &&
        today.difference(DateTime(last.year, last.month, last.day)).inDays == 1;
    final streak = continues ? progress.dailyStreak + 1 : 1;
    final coins = dailyCoins(streak);
    var updated = progress.copyWith(
      coins: progress.coins + coins,
      dailyStreak: streak,
      lastDailyClaim: today,
    );
    final earned = <Achievement>[
      if (streak >= 3 &&
          !updated.achievements.contains(Achievement.dailyStreak3))
        Achievement.dailyStreak3,
    ];
    updated = _grant(updated, earned);
    return (updated, coins + earned.fold(0, (sum, a) => sum + a.coins));
  }

  static List<Achievement> _gameAchievements(
    PlayerProgress progress,
    GameSummary game,
  ) {
    final won = game.result == PlayerResult.win;
    final vsComputer = game.mode == PlayedMode.computer;
    final candidates = <Achievement>[
      Achievement.firstGame,
      if (won && vsComputer) Achievement.firstWin,
      if (game.castled) Achievement.castling,
      if (game.promoted) Achievement.promotion,
      if (game.enPassant) Achievement.enPassant,
      if (won && vsComputer && game.hintsUsed == 0 && game.undosUsed == 0)
        Achievement.pureWin,
      if (won && game.playerMoves <= 20 && game.mode != PlayedMode.local)
        Achievement.quickWin,
      if (progress.stats.checkmates >= 5) Achievement.checkmates5,
      if (won && vsComputer && (game.aiLevel ?? 0) >= 5) Achievement.beatLevel5,
      if (won && vsComputer && (game.aiLevel ?? 0) >= 10)
        Achievement.beatLevel10,
      if (game.mode == PlayedMode.local) Achievement.friendlyGame,
      if (game.mode == PlayedMode.lan) Achievement.lanGame,
      if (progress.stats.wins >= 10) Achievement.tenWins,
    ];
    return [
      for (final a in candidates)
        if (!progress.achievements.contains(a)) a,
    ];
  }

  static PlayerProgress _grant(
    PlayerProgress progress,
    List<Achievement> earned,
  ) {
    if (earned.isEmpty) return progress;
    return progress.copyWith(
      achievements: {...progress.achievements, ...earned},
      coins: progress.coins + earned.fold(0, (sum, a) => sum + a.coins),
    );
  }
}
