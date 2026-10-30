import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../history/presentation/game_record_tile.dart';
import '../../history/presentation/game_review_page.dart';
import '../../history/presentation/history_cubit.dart';
import '../../lessons/domain/lesson_catalog.dart';
import '../../settings/domain/app_settings.dart';
import '../../shop/presentation/shop_page.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/achievement.dart';
import '../domain/player_progress.dart';
import '../domain/player_rank.dart';
import 'achievement_style.dart';
import 'progress_cubit.dart';
import 'widgets/player_avatar.dart';

/// The player's card, achievements, game history and statistics.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final progress = context.watch<ProgressCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: Text(s.profileTitle)),
        body: RoyalBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _ProfileHeader(progress: progress, settings: settings),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.outline),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        gradient: palette.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: [
                        Tab(text: s.achievementsTab),
                        Tab(text: s.historyTab),
                        Tab(text: s.statsTab),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AchievementsTab(progress: progress),
                      const _HistoryTab(),
                      _StatsTab(progress: progress),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.progress, required this.settings});

  final PlayerProgress progress;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final level = progress.level;
    final start = PlayerRank.xpForLevel(level);
    final end = PlayerRank.xpForLevel(level + 1);
    return GlassCard(
      child: Row(
        children: [
          const PlayerAvatar(size: 64, glow: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.playerName.isEmpty ? s.you : settings.playerName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${s.levelLabel(level)} · ${displayTitle(s, settings, progress)}',
                  style: TextStyle(
                    color: palette.accentLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                GoldProgressBar(value: PlayerRank.progressInLevel(progress.xp)),
                const SizedBox(height: 4),
                Text(
                  s.xpProgress(progress.xp - start, end - start),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              CoinChip(coins: progress.coins),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ShopPage()),
                ),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: Text(s.shopTitle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: Achievement.values.length,
      itemBuilder: (context, index) {
        final palette = context.palette;
        final achievement = Achievement.values[index];
        final earned = progress.achievements.contains(achievement);
        final color = earned ? achievement.color : AppColors.textMuted;
        return GlassCard(
          padding: const EdgeInsets.all(12),
          borderColor: earned ? color.withValues(alpha: 0.6) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: earned ? 0.18 : 0.08),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    if (earned)
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 16,
                      ),
                  ],
                ),
                child: Icon(
                  earned ? achievement.icon : Icons.lock_rounded,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.achievementTitle(achievement),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: earned
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.achievementDescription(achievement),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${achievement.coins}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.accentLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final games = context.watch<HistoryCubit>().state.games;
    if (games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.s.historyEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => GameRecordTile(
        record: games[index],
        onTap: () =>
            AppRoutes.push(context, GameReviewPage(record: games[index])),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final stats = progress.stats;
    final items = <(IconData, String, String, Color)>[
      (
        Icons.sports_esports_rounded,
        s.gamesPlayed,
        '${stats.played}',
        AppColors.sapphire,
      ),
      (
        Icons.emoji_events_rounded,
        s.winsLabel,
        '${stats.wins}',
        palette.accent,
      ),
      (
        Icons.handshake_rounded,
        s.drawsLabel,
        '${stats.draws}',
        AppColors.textSecondary,
      ),
      (
        Icons.sentiment_dissatisfied_rounded,
        s.lossesLabel,
        '${stats.losses}',
        AppColors.ruby,
      ),
      (
        Icons.percent_rounded,
        s.winRate,
        '${(stats.winRate * 100).round()}%',
        AppColors.emerald,
      ),
      (
        Icons.workspace_premium_rounded,
        s.checkmatesLabel,
        '${stats.checkmates}',
        AppColors.amethyst,
      ),
      (
        Icons.star_rounded,
        s.starsLabel,
        '${progress.totalStars}/${PlayerProgress.computerLevels * 3}',
        palette.accent,
      ),
      (
        Icons.school_rounded,
        s.lessonsLabel,
        '${progress.completedLessons.length}/${LessonCatalog.lessons.length}',
        AppColors.amethyst,
      ),
    ];
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        for (final (icon, label, value, color) in items)
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}
