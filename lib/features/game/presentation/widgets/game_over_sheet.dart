import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/royal_button.dart';
import '../../../../engine/chess_engine.dart';
import '../../../progress/domain/reward_rules.dart';
import '../../../progress/presentation/achievement_style.dart';
import '../../domain/game_config.dart';
import '../../domain/game_outcome.dart';

/// What the player chose on the game-over sheet.
enum GameOverAction { playAgain, nextLevel, rematch, home, viewBoard }

/// Shows the result, the rewards earned and the next steps.
Future<GameOverAction?> showGameOverSheet(
  BuildContext context, {
  required GameOutcome outcome,
  required GameConfig config,
  required GameRewards? rewards,
}) {
  return showModalBottomSheet<GameOverAction>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) =>
        _GameOverSheet(outcome: outcome, config: config, rewards: rewards),
  );
}

class _GameOverSheet extends StatelessWidget {
  const _GameOverSheet({
    required this.outcome,
    required this.config,
    required this.rewards,
  });

  final GameOutcome outcome;
  final GameConfig config;
  final GameRewards? rewards;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final winner = outcome.winner;
    final local = config.mode == GameMode.local;
    final won = !local && winner == config.playerColor;
    final lost = !local && winner != null && winner != config.playerColor;

    final String title;
    if (winner == null) {
      title = s.draw;
    } else if (local) {
      final name = winner == PieceColor.white
          ? config.whiteName
          : config.blackName;
      title = s.wins(name ?? s.colorName(winner));
    } else {
      title = won ? s.youWon : s.youLost;
    }
    final (icon, color) = switch ((winner, lost)) {
      (null, _) => (Icons.handshake_rounded, AppColors.sapphire),
      (_, true) => (Icons.sentiment_dissatisfied_rounded, AppColors.ruby),
      _ => (Icons.emoji_events_rounded, palette.accent),
    };

    final rewards = this.rewards;
    final nextLevel =
        config.mode == GameMode.computer &&
        won &&
        (config.aiLevel?.number ?? 10) < 10;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 50),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              s.outcomeReason(outcome.reason),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (rewards != null) ...[
              const SizedBox(height: 18),
              _RewardsCard(rewards: rewards),
            ],
            const SizedBox(height: 20),
            if (nextLevel)
              RoyalButton(
                label: s.nextLevel,
                icon: Icons.keyboard_double_arrow_up_rounded,
                onPressed: () =>
                    Navigator.of(context).pop(GameOverAction.nextLevel),
              )
            else if (config.mode == GameMode.lan)
              RoyalButton(
                label: s.rematch,
                icon: Icons.replay_rounded,
                onPressed: () =>
                    Navigator.of(context).pop(GameOverAction.rematch),
              )
            else
              RoyalButton(
                label: s.playAgain,
                icon: Icons.replay_rounded,
                onPressed: () =>
                    Navigator.of(context).pop(GameOverAction.playAgain),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: s.viewBoard,
                    icon: Icons.grid_view_rounded,
                    onPressed: () =>
                        Navigator.of(context).pop(GameOverAction.viewBoard),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton(
                    label: s.backHome,
                    icon: Icons.home_rounded,
                    onPressed: () =>
                        Navigator.of(context).pop(GameOverAction.home),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.rewards});

  final GameRewards rewards;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            palette.accent.withValues(alpha: 0.18),
            palette.accent.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        children: [
          Text(s.rewards, style: Theme.of(context).textTheme.titleMedium),
          if (rewards.stars != null) ...[
            const SizedBox(height: 8),
            StarRow(stars: rewards.stars!, size: 40),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountUp(
                value: rewards.xp,
                builder: (v) => s.xpGained(v),
                icon: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 24),
              _CountUp(
                value: rewards.coins,
                builder: (v) => s.coinsGained(v),
                icon: const CoinIcon(size: 22),
              ),
            ],
          ),
          if (rewards.boosted) ...[
            const SizedBox(height: 8),
            _Banner(
              icon: Icons.bolt_rounded,
              color: AppColors.amber,
              text: s.doubleXp,
            ),
          ],
          if (rewards.leveledUp) ...[
            const SizedBox(height: 10),
            _Banner(
              icon: Icons.arrow_circle_up_rounded,
              text: s.levelUp(rewards.levelAfter),
              color: AppColors.emerald,
            ),
          ],
          if (rewards.unlockedComputerLevel != null) ...[
            const SizedBox(height: 8),
            _Banner(
              icon: Icons.lock_open_rounded,
              text: s.levelUnlocked(rewards.unlockedComputerLevel!),
              color: palette.accent,
            ),
          ],
          for (final achievement in rewards.newAchievements) ...[
            const SizedBox(height: 8),
            _Banner(
              icon: achievement.icon,
              text:
                  '${s.newAchievement}: ${s.achievementTitle(achievement)} (+${achievement.coins})',
              color: achievement.color,
            ),
          ],
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  const _CountUp({
    required this.value,
    required this.builder,
    required this.icon,
  });

  final int value;
  final String Function(int value) builder;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => Row(
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            builder(current.round()),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
