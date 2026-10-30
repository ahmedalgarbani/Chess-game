import 'package:chess_game/features/progress/domain/achievement.dart';
import 'package:chess_game/features/progress/domain/game_summary.dart';
import 'package:chess_game/features/progress/domain/player_progress.dart';
import 'package:chess_game/features/progress/domain/player_rank.dart';
import 'package:chess_game/features/progress/domain/reward_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerRank', () {
    test('levels follow the experience curve', () {
      expect(PlayerRank.levelForXp(0), 1);
      expect(PlayerRank.levelForXp(99), 1);
      expect(PlayerRank.levelForXp(100), 2);
      expect(PlayerRank.levelForXp(300), 3);
      expect(PlayerRank.progressInLevel(150), closeTo(0.25, 1e-9));
    });
  });

  group('RewardRules', () {
    test('first win against the computer unlocks the next level', () {
      const progress = PlayerProgress();
      final (updated, rewards) = RewardRules.applyGame(
        progress,
        const GameSummary(
          mode: PlayedMode.computer,
          result: PlayerResult.win,
          aiLevel: 1,
          byCheckmate: true,
          playerMoves: 18,
          castled: true,
        ),
      );
      expect(rewards.stars, 3);
      expect(rewards.unlockedComputerLevel, 2);
      expect(updated.highestUnlockedLevel, 2);
      expect(updated.levelStars, {1: 3});
      expect(
        rewards.newAchievements,
        containsAll([
          Achievement.firstGame,
          Achievement.firstWin,
          Achievement.castling,
          Achievement.pureWin,
          Achievement.quickWin,
        ]),
      );
      expect(updated.coins, progress.coins + rewards.coins);
      expect(updated.stats.wins, 1);
      expect(updated.stats.checkmates, 1);
    });

    test('hints and undo reduce the stars, and achievements pay once', () {
      final (first, _) = RewardRules.applyGame(
        const PlayerProgress(),
        const GameSummary(
          mode: PlayedMode.computer,
          result: PlayerResult.win,
          aiLevel: 2,
          hintsUsed: 5,
          playerMoves: 40,
        ),
      );
      expect(first.levelStars[2], 1);
      final (_, second) = RewardRules.applyGame(
        first,
        const GameSummary(
          mode: PlayedMode.computer,
          result: PlayerResult.win,
          aiLevel: 2,
          playerMoves: 40,
        ),
      );
      expect(second.stars, 3);
      expect(second.newAchievements, isNot(contains(Achievement.firstGame)));
      expect(second.unlockedComputerLevel, isNull);
    });

    test('daily reward grows with the streak and resets after a gap', () {
      var progress = const PlayerProgress();
      final day1 = DateTime(2026, 1, 1, 10);
      final (p1, coins1) = RewardRules.claimDaily(progress, day1)!;
      expect(coins1, 20);
      expect(
        RewardRules.claimDaily(p1, day1.add(const Duration(hours: 5))),
        isNull,
      );
      final (p2, coins2) = RewardRules.claimDaily(p1, DateTime(2026, 1, 2, 9))!;
      expect(coins2, 30);
      final (p3, coins3) = RewardRules.claimDaily(
        p2,
        DateTime(2026, 1, 3, 23),
      )!;
      expect(p3.dailyStreak, 3);
      expect(p3.achievements, contains(Achievement.dailyStreak3));
      expect(coins3, 40 + Achievement.dailyStreak3.coins);
      progress = p3;
      final (p4, coins4) = RewardRules.claimDaily(
        progress,
        DateTime(2026, 1, 6),
      )!;
      expect(p4.dailyStreak, 1);
      expect(coins4, 20);
    });

    test('lessons reward once', () {
      final (updated, rewards) = RewardRules.applyLesson(
        const PlayerProgress(),
        'pawn',
        totalLessons: 2,
      )!;
      expect(rewards.xp, RewardRules.lessonXp);
      expect(RewardRules.applyLesson(updated, 'pawn', totalLessons: 2), isNull);
      final (done, last) = RewardRules.applyLesson(
        updated,
        'rook',
        totalLessons: 2,
      )!;
      expect(last.newAchievements, [Achievement.allLessons]);
      expect(done.completedLessons, {'pawn', 'rook'});
    });
  });

  test('progress survives a JSON round trip', () {
    final (progress, _) = RewardRules.applyGame(
      const PlayerProgress(),
      const GameSummary(
        mode: PlayedMode.computer,
        result: PlayerResult.win,
        aiLevel: 3,
      ),
    );
    final restored = PlayerProgress.fromJson(progress.toJson());
    expect(restored.xp, progress.xp);
    expect(restored.coins, progress.coins);
    expect(restored.levelStars, progress.levelStars);
    expect(restored.achievements, progress.achievements);
    expect(restored.stats.wins, 1);
  });
}
