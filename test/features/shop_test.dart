import 'package:chess_game/features/progress/domain/achievement.dart';
import 'package:chess_game/features/progress/domain/game_summary.dart';
import 'package:chess_game/features/progress/domain/player_progress.dart';
import 'package:chess_game/features/progress/domain/reward_rules.dart';
import 'package:chess_game/features/progress/domain/shop_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('purchases', () {
    test('a cosmetic is bought once and pays the first-purchase award', () {
      const progress = PlayerProgress(coins: 500);
      expect(progress.owns(CosmeticKind.board, 'emerald'), isFalse);
      final (bought, earned) = RewardRules.purchase(
        progress,
        CosmeticKind.board,
        'emerald',
        200,
      )!;
      expect(bought.owns(CosmeticKind.board, 'emerald'), isTrue);
      expect(earned, [Achievement.firstPurchase]);
      expect(bought.coins, 500 - 200 + Achievement.firstPurchase.coins);
      expect(
        RewardRules.purchase(bought, CosmeticKind.board, 'emerald', 200),
        isNull,
      );
    });

    test('starter items are owned and unaffordable items are refused', () {
      const progress = PlayerProgress(coins: 10);
      expect(progress.owns(CosmeticKind.appTheme, 'royal'), isTrue);
      expect(progress.owns(CosmeticKind.title, ''), isTrue);
      expect(
        RewardRules.purchase(progress, CosmeticKind.appTheme, 'ocean', 450),
        isNull,
      );
      expect(RewardRules.purchaseBoost(progress, Boost.hintPack), isNull);
    });

    test('collecting enough cosmetics earns the collector award', () {
      var progress = const PlayerProgress(coins: 100000);
      final earned = <Achievement>[];
      for (var i = 0; i < RewardRules.collectorItems; i++) {
        final (next, awards) = RewardRules.purchase(
          progress,
          CosmeticKind.title,
          'title$i',
          10,
        )!;
        progress = next;
        earned.addAll(awards);
      }
      expect(earned, [Achievement.firstPurchase, Achievement.collector]);
    });
  });

  group('boosts', () {
    test('a hint pack adds hints that are spent one by one', () {
      final (progress, _) = RewardRules.purchaseBoost(
        const PlayerProgress(coins: 100),
        Boost.hintPack,
      )!;
      expect(progress.hintTokens, Boost.hintPack.amount);
      var current = progress;
      for (var i = 0; i < Boost.hintPack.amount; i++) {
        current = RewardRules.spendHintToken(current)!;
      }
      expect(current.hintTokens, 0);
      expect(RewardRules.spendHintToken(current), isNull);
    });

    test('an XP booster doubles experience for its games', () {
      const game = GameSummary(
        mode: PlayedMode.local,
        result: PlayerResult.draw,
      );
      final (plain, normal) = RewardRules.applyGame(
        const PlayerProgress(),
        game,
      );
      final (boosted, doubled) = RewardRules.applyGame(
        const PlayerProgress(xpBoostGames: 1),
        game,
      );
      expect(normal.boosted, isFalse);
      expect(doubled.boosted, isTrue);
      expect(doubled.xp, normal.xp * 2);
      expect(boosted.xpBoostGames, 0);
      expect(plain.xpBoostGames, 0);
    });

    test('a streak shield bridges one missed day only', () {
      final monday = DateTime(2026, 3, 2, 9);
      final progress = PlayerProgress(
        dailyStreak: 4,
        lastDailyClaim: monday,
        streakShields: 1,
      );
      final wednesday = monday.add(const Duration(days: 2));
      final (shielded, _) = RewardRules.claimDaily(progress, wednesday)!;
      expect(shielded.dailyStreak, 5);
      expect(shielded.streakShields, 0);

      final thursday = monday.add(const Duration(days: 3));
      final (reset, _) = RewardRules.claimDaily(progress, thursday)!;
      expect(reset.dailyStreak, 1);
      expect(reset.streakShields, 1);
    });
  });

  group('puzzles', () {
    final now = DateTime(2026, 5, 10, 18);

    test('a puzzle pays once, the daily bonus once a day', () {
      final (first, rewards) = RewardRules.applyPuzzle(
        const PlayerProgress(),
        'p1',
        coins: 20,
        xp: 30,
        isDaily: true,
        totalPuzzles: 50,
        now: now,
      )!;
      expect(rewards.xp, 30);
      expect(
        rewards.coins,
        20 + RewardRules.dailyPuzzleBonus + Achievement.dailyPuzzle.coins,
      );
      expect(first.solvedDailyPuzzle(now), isTrue);
      expect(
        RewardRules.applyPuzzle(
          first,
          'p1',
          coins: 20,
          xp: 30,
          isDaily: true,
          totalPuzzles: 50,
          now: now,
        ),
        isNull,
      );

      // The next day the same puzzle can be the daily one again.
      final (_, tomorrow) = RewardRules.applyPuzzle(
        first,
        'p1',
        coins: 20,
        xp: 30,
        isDaily: true,
        totalPuzzles: 50,
        now: now.add(const Duration(days: 1)),
      )!;
      expect(tomorrow.xp, 0);
      expect(tomorrow.coins, RewardRules.dailyPuzzleBonus);
    });
  });

  group('saving', () {
    test('purchases and boosts survive a JSON round trip', () {
      var (progress, _) = RewardRules.purchase(
        const PlayerProgress(coins: 1000),
        CosmeticKind.frame,
        'flame',
        450,
      )!;
      (progress, _) = RewardRules.purchaseBoost(progress, Boost.streakShield)!;
      progress = progress.copyWith(solvedPuzzles: {'p3'});
      final restored = PlayerProgress.fromJson(progress.toJson());
      expect(restored.owns(CosmeticKind.frame, 'flame'), isTrue);
      expect(restored.streakShields, 1);
      expect(restored.solvedPuzzles, {'p3'});
      expect(restored.coins, progress.coins);
    });

    test('collections saved by the previous version are kept', () {
      final restored = PlayerProgress.fromJson({
        'coins': 120,
        'ownedBoardThemes': ['royal', 'emerald'],
        'ownedPieceStyles': ['classic', 'emeraldRuby'],
      });
      expect(restored.owns(CosmeticKind.board, 'emerald'), isTrue);
      expect(restored.owns(CosmeticKind.pieces, 'emeraldRuby'), isTrue);
      expect(restored.owns(CosmeticKind.appTheme, 'ocean'), isFalse);
    });
  });
}
