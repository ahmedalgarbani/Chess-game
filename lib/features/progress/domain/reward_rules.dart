import 'achievement.dart';
import 'game_summary.dart';
import 'player_progress.dart';
import 'shop_items.dart';

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
    this.boosted = false,
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

  /// Whether an XP booster doubled [xp].
  final bool boosted;

  bool get leveledUp => levelAfter > levelBefore;
}

/// The rules that turn games, lessons, puzzles and daily visits into
/// rewards, and that govern spending coins in the shop.
abstract final class RewardRules {
  static const int lessonXp = 30;
  static const int lessonCoins = 15;

  /// Extra coins for solving the puzzle of the day.
  static const int dailyPuzzleBonus = 50;

  /// Purchased cosmetics needed for the collector achievement.
  static const int collectorItems = 8;

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

    final boosted = progress.xpBoostGames > 0;
    if (boosted) xp *= 2;

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
      xpBoostGames: boosted ? progress.xpBoostGames - 1 : null,
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
        boosted: boosted,
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

  /// The streak the next daily claim would reach. A streak shield bridges
  /// a single missed day.
  static int nextDailyStreak(PlayerProgress progress, DateTime now) =>
      _nextStreak(progress, now).$1;

  /// The next streak and whether a streak shield is needed for it.
  static (int, bool) _nextStreak(PlayerProgress progress, DateTime now) {
    final last = progress.lastDailyClaim;
    if (last == null) return (1, false);
    final today = DateTime(now.year, now.month, now.day);
    final gap = today
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;
    if (gap == 1) return (progress.dailyStreak + 1, false);
    if (gap == 2 && progress.streakShields > 0) {
      return (progress.dailyStreak + 1, true);
    }
    return (1, false);
  }

  /// Claims the daily reward. Returns null if it was already claimed today.
  static (PlayerProgress, int)? claimDaily(
    PlayerProgress progress,
    DateTime now,
  ) {
    if (!progress.canClaimDaily(now)) return null;
    final today = DateTime(now.year, now.month, now.day);
    final (streak, usesShield) = _nextStreak(progress, now);
    final coins = dailyCoins(streak);
    var updated = progress.copyWith(
      coins: progress.coins + coins,
      dailyStreak: streak,
      lastDailyClaim: today,
      streakShields: usesShield ? progress.streakShields - 1 : null,
    );
    final earned = <Achievement>[
      if (streak >= 3 &&
          !updated.achievements.contains(Achievement.dailyStreak3))
        Achievement.dailyStreak3,
    ];
    updated = _grant(updated, earned);
    return (updated, coins + earned.fold(0, (sum, a) => sum + a.coins));
  }

  /// Marks a puzzle as solved and pays its reward the first time. Solving
  /// the puzzle of the day also pays [dailyPuzzleBonus] once per day.
  /// Returns null when nothing is earned.
  static (PlayerProgress, GameRewards)? applyPuzzle(
    PlayerProgress progress,
    String puzzleId, {
    required int coins,
    required int xp,
    required bool isDaily,
    required int totalPuzzles,
    required DateTime now,
  }) {
    final firstSolve = !progress.solvedPuzzles.contains(puzzleId);
    final dailyBonus = isDaily && !progress.solvedDailyPuzzle(now);
    if (!firstSolve && !dailyBonus) return null;
    final earnedCoins =
        (firstSolve ? coins : 0) + (dailyBonus ? dailyPuzzleBonus : 0);
    final earnedXp = firstSolve ? xp : 0;
    var updated = progress.copyWith(
      xp: progress.xp + earnedXp,
      coins: progress.coins + earnedCoins,
      solvedPuzzles: {...progress.solvedPuzzles, puzzleId},
      lastDailyPuzzle: dailyBonus
          ? DateTime(now.year, now.month, now.day)
          : null,
    );
    final solved = updated.solvedPuzzles.length;
    final earned = [
      for (final (achievement, unlocked) in [
        (Achievement.puzzles10, solved >= 10),
        (Achievement.allPuzzles, solved >= totalPuzzles),
        (Achievement.dailyPuzzle, dailyBonus),
      ])
        if (unlocked && !updated.achievements.contains(achievement))
          achievement,
    ];
    updated = _grant(updated, earned);
    return (
      updated,
      GameRewards(
        xp: earnedXp,
        coins: earnedCoins + earned.fold(0, (sum, a) => sum + a.coins),
        levelBefore: progress.level,
        levelAfter: updated.level,
        newAchievements: earned,
      ),
    );
  }

  /// Buys a cosmetic. Returns null if it is already owned or unaffordable.
  static (PlayerProgress, List<Achievement>)? purchase(
    PlayerProgress progress,
    CosmeticKind kind,
    String id,
    int price,
  ) {
    if (progress.owns(kind, id) || progress.coins < price) return null;
    var updated = progress
        .withOwned(kind, id)
        .copyWith(coins: progress.coins - price);
    final earned = _purchaseAchievements(updated);
    updated = _grant(updated, earned);
    return (updated, earned);
  }

  /// Buys a boost. Returns null if it is unaffordable.
  static (PlayerProgress, List<Achievement>)? purchaseBoost(
    PlayerProgress progress,
    Boost boost,
  ) {
    if (progress.coins < boost.price) return null;
    var updated = progress.copyWith(
      coins: progress.coins - boost.price,
      hintTokens: boost == Boost.hintPack
          ? progress.hintTokens + boost.amount
          : null,
      xpBoostGames: boost == Boost.xpBooster
          ? progress.xpBoostGames + boost.amount
          : null,
      streakShields: boost == Boost.streakShield
          ? progress.streakShields + boost.amount
          : null,
    );
    final earned = _purchaseAchievements(updated);
    updated = _grant(updated, earned);
    return (updated, earned);
  }

  /// Uses one purchased hint. Returns null when none is left.
  static PlayerProgress? spendHintToken(PlayerProgress progress) =>
      progress.hintTokens > 0
      ? progress.copyWith(hintTokens: progress.hintTokens - 1)
      : null;

  static List<Achievement> _purchaseAchievements(PlayerProgress progress) => [
    if (!progress.achievements.contains(Achievement.firstPurchase))
      Achievement.firstPurchase,
    if (progress.purchasedCount >= collectorItems &&
        !progress.achievements.contains(Achievement.collector))
      Achievement.collector,
  ];

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
