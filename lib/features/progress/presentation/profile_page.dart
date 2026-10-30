import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/chess_ui/piece_painter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../engine/chess_engine.dart';
import '../../lessons/domain/lesson_catalog.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/achievement.dart';
import '../domain/player_progress.dart';
import '../domain/player_rank.dart';
import 'achievement_style.dart';
import 'progress_cubit.dart';

/// Achievements, the unlockable collection and statistics.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: [
                        Tab(text: s.achievementsTab),
                        Tab(text: s.collectionTab),
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
                      _CollectionTab(progress: progress, settings: settings),
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
    final s = context.s;
    final level = progress.level;
    final start = PlayerRank.xpForLevel(level);
    final end = PlayerRank.xpForLevel(level + 1);
    return GlassCard(
      child: Row(
        children: [
          const PieceMedallion(piece: Piece.whiteKing, size: 64, glow: true),
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
                  '${s.levelLabel(level)} · ${s.rankTitle(progress.title)}',
                  style: const TextStyle(
                    color: AppColors.goldLight,
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
          CoinChip(coins: progress.coins),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldLight,
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

class _CollectionTab extends StatelessWidget {
  const _CollectionTab({required this.progress, required this.settings});

  final PlayerProgress progress;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final style = PieceStyle.byId(settings.pieceStyleId);
    final board = BoardTheme.byId(settings.boardThemeId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionTitle(s.boardThemes),
        for (final theme in BoardTheme.all)
          _CollectionItem(
            name: s.boardThemeName(theme.id),
            price: theme.price,
            owned:
                progress.ownedBoardThemes.contains(theme.id) ||
                theme.price == 0,
            selected: settings.boardThemeId == theme.id,
            preview: _BoardPreview(theme: theme, style: style),
            onBuy: () => context.read<ProgressCubit>().buyBoardTheme(
              theme.id,
              theme.price,
            ),
            onUse: () => context.read<SettingsCubit>().update(
              (s) => s.copyWith(boardThemeId: theme.id),
            ),
          ),
        const SizedBox(height: 12),
        SectionTitle(s.pieceStyles),
        for (final pieceStyle in PieceStyle.all)
          _CollectionItem(
            name: s.pieceStyleName(pieceStyle.id),
            price: pieceStyle.price,
            owned:
                progress.ownedPieceStyles.contains(pieceStyle.id) ||
                pieceStyle.price == 0,
            selected: settings.pieceStyleId == pieceStyle.id,
            preview: _BoardPreview(theme: board, style: pieceStyle),
            onBuy: () => context.read<ProgressCubit>().buyPieceStyle(
              pieceStyle.id,
              pieceStyle.price,
            ),
            onUse: () => context.read<SettingsCubit>().update(
              (s) => s.copyWith(pieceStyleId: pieceStyle.id),
            ),
          ),
      ],
    );
  }
}

class _CollectionItem extends StatelessWidget {
  const _CollectionItem({
    required this.name,
    required this.price,
    required this.owned,
    required this.selected,
    required this.preview,
    required this.onBuy,
    required this.onUse,
  });

  final String name;
  final int price;
  final bool owned;
  final bool selected;
  final Widget preview;
  final bool Function() onBuy;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final Widget action;
    if (selected) {
      action = Chip(
        avatar: const Icon(
          Icons.check_rounded,
          size: 18,
          color: AppColors.background,
        ),
        label: Text(s.inUse),
        backgroundColor: AppColors.gold,
        labelStyle: const TextStyle(color: AppColors.background),
      );
    } else if (owned) {
      action = OutlinedButton(onPressed: onUse, child: Text(s.use));
    } else {
      action = FilledButton.icon(
        onPressed: () {
          final messenger = ScaffoldMessenger.of(context);
          if (onBuy()) {
            onUse();
            messenger.showSnackBar(SnackBar(content: Text(s.purchased(name))));
          } else {
            messenger.showSnackBar(SnackBar(content: Text(s.notEnoughCoins)));
          }
        },
        icon: const CoinIcon(size: 16),
        label: Text('$price'),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderColor: selected ? AppColors.gold : null,
        child: Row(
          children: [
            SizedBox(width: 92, height: 46, child: preview),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.theme, required this.style});

  final BoardTheme theme;
  final PieceStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          for (final (index, piece) in const [
            Piece.whiteKing,
            Piece.blackQueen,
          ].indexed)
            Expanded(
              child: ColoredBox(
                color: index.isEven ? theme.light : theme.dark,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: PieceView(piece: piece, style: style, shadow: false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
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
        AppColors.gold,
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
        AppColors.gold,
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
