import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/chess_ui/piece_painter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../core/widgets/royal_button.dart';
import '../../../engine/chess_engine.dart';
import '../../game/domain/game_config.dart';
import '../../game/domain/game_snapshot.dart';
import '../../game/presentation/pages/game_page.dart';
import '../../game/presentation/pages/game_setup_sheet.dart';
import '../../history/presentation/history_cubit.dart';
import '../../lan/presentation/lan_lobby_page.dart';
import '../../lessons/domain/lesson_catalog.dart';
import '../../lessons/presentation/lessons_page.dart';
import '../../levels/presentation/levels_page.dart';
import '../../progress/domain/player_progress.dart';
import '../../progress/domain/player_rank.dart';
import '../../progress/domain/reward_rules.dart';
import '../../progress/presentation/profile_page.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../../progress/presentation/widgets/player_avatar.dart';
import '../../puzzles/domain/puzzle_catalog.dart';
import '../../puzzles/presentation/puzzles_page.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../../settings/presentation/settings_page.dart';
import '../../shop/presentation/shop_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final progress = context.watch<ProgressCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final canClaim = context.read<ProgressCubit>().canClaimDaily;
    final lessonsDone = progress.completedLessons.length;
    final totalLessons = LessonCatalog.lessons.length;
    final showLearning = settings.learningMode && lessonsDone < totalLessons;
    final now = DateTime.now();
    final unfinished = context.watch<HistoryCubit>().state.unfinished;

    return Scaffold(
      body: RoyalBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _Header(progress: progress, settings: settings),
              const SizedBox(height: 18),
              if (unfinished != null) ...[
                _ResumeCard(game: unfinished),
                const SizedBox(height: 14),
              ],
              if (canClaim) ...[
                _DailyRewardCard(progress: progress),
                const SizedBox(height: 14),
              ],
              if (!progress.solvedDailyPuzzle(now)) ...[
                DailyPuzzleCard(puzzle: PuzzleCatalog.daily(now), done: false),
                const SizedBox(height: 14),
              ],
              if (showLearning) ...[
                _ContinueLearningCard(done: lessonsDone, total: totalLessons),
                const SizedBox(height: 14),
              ],
              _ModeCard(
                title: s.modeComputer,
                subtitle: s.modeComputerSubtitle(progress.highestUnlockedLevel),
                piece: Piece.blackKing,
                accent: palette.accent,
                onTap: () => AppRoutes.push(context, const LevelsPage()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: palette.accent, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.totalStars} / ${PlayerProgress.computerLevels * 3}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: palette.accentLight,
                      ),
                    ),
                  ],
                ),
                large: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: s.modeLocal,
                      subtitle: s.modeLocalSubtitle,
                      piece: Piece.whiteKnight,
                      accent: AppColors.emerald,
                      onTap: () => showLocalGameSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      title: s.modeLan,
                      subtitle: s.modeLanSubtitle,
                      piece: Piece.blackRook,
                      accent: AppColors.sapphire,
                      onTap: () =>
                          AppRoutes.push(context, const LanLobbyPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: s.modeLearn,
                      subtitle: s.modeLearnSubtitle(lessonsDone, totalLessons),
                      piece: Piece.whitePawn,
                      accent: AppColors.amethyst,
                      onTap: () => AppRoutes.push(context, const LessonsPage()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      title: s.puzzlesTitle,
                      subtitle: s.modePuzzlesSubtitle(
                        progress.solvedPuzzles.length,
                        PuzzleCatalog.puzzles.length,
                      ),
                      piece: Piece.blackKnight,
                      accent: AppColors.sapphire,
                      onTap: () => AppRoutes.push(context, const PuzzlesPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: s.quickPlay,
                      subtitle: s.quickPlaySubtitle,
                      piece: Piece.whiteQueen,
                      accent: AppColors.ruby,
                      onTap: () => showComputerGameSheet(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeCard(
                      title: s.shopTitle,
                      subtitle: s.modeShopSubtitle,
                      piece: Piece.blackQueen,
                      accent: AppColors.amber,
                      onTap: () => AppRoutes.push(context, const ShopPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ModeCard(
                title: s.modeProfile,
                subtitle: s.modeProfileSubtitle,
                piece: Piece.whiteBishop,
                accent: palette.accentLight,
                onTap: () => AppRoutes.push(context, const ProfilePage()),
                large: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.settings});

  final PlayerProgress progress;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final level = progress.level;
    final start = PlayerRank.xpForLevel(level);
    final end = PlayerRank.xpForLevel(level + 1);
    return Row(
      children: [
        GestureDetector(
          onTap: () => AppRoutes.push(context, const ProfilePage()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const PlayerAvatar(size: 58),
              PositionedDirectional(
                bottom: -4,
                end: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: palette.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.background, width: 2),
                  ),
                  child: Text(
                    '$level',
                    style: TextStyle(
                      color: palette.onAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.greeting(settings.playerName),
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${displayTitle(s, settings, progress)} · ${s.xpProgress(progress.xp - start, end - start)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              GoldProgressBar(value: PlayerRank.progressInLevel(progress.xp)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleIconButton(
              icon: Icons.settings_rounded,
              tooltip: s.settings,
              size: 40,
              onPressed: () => AppRoutes.push(context, const SettingsPage()),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => AppRoutes.push(context, const ShopPage()),
              child: CoinChip(coins: progress.coins, compact: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final nextStreak = RewardRules.nextDailyStreak(progress, DateTime.now());
    return GlassCard(
      borderColor: palette.accent.withValues(alpha: 0.6),
      gradient: LinearGradient(
        colors: [
          palette.accent.withValues(alpha: 0.25),
          palette.accent.withValues(alpha: 0.06),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            color: palette.accentLight,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.dailyRewardTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  s.dailyRewardBody(RewardRules.dailyCoins(nextStreak)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RoyalButton(
            label: s.claim,
            expanded: false,
            onPressed: () {
              final coins = context.read<ProgressCubit>().claimDaily();
              if (coins != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.dailyClaimed(coins))));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.game});

  final GameSnapshot game;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final config = game.config;
    final opponent = config.mode == GameMode.local
        ? s.modeLocal
        : (config.playerColor == PieceColor.white
                  ? config.blackName
                  : config.whiteName) ??
              s.colorName(config.playerColor.opposite);
    return GlassCard(
      borderColor: AppColors.emerald.withValues(alpha: 0.6),
      gradient: LinearGradient(
        colors: [
          AppColors.emerald.withValues(alpha: 0.25),
          AppColors.emerald.withValues(alpha: 0.05),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.emerald,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.resumeGame,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      s.resumeGameSubtitle(
                        opponent,
                        (game.moves.length + 1) ~/ 2,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RoyalButton(
                  label: s.resumeGame,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => AppRoutes.push(
                    context,
                    GamePage(config: config, resumeFrom: game),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () =>
                    context.read<HistoryCubit>().discardUnfinished(),
                style: TextButton.styleFrom(
                  foregroundColor: palette.accentLight,
                ),
                child: Text(s.discard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return GlassCard(
      onTap: () => AppRoutes.push(context, const LessonsPage()),
      borderColor: AppColors.amethyst.withValues(alpha: 0.5),
      gradient: LinearGradient(
        colors: [
          AppColors.amethyst.withValues(alpha: 0.25),
          AppColors.amethyst.withValues(alpha: 0.05),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: AppColors.amethyst, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.continueLearning,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                GoldProgressBar(
                  value: total == 0 ? 0 : done / total,
                  height: 6,
                ),
                const SizedBox(height: 4),
                Text(
                  s.modeLearnSubtitle(done, total),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.piece,
    required this.accent,
    required this.onTap,
    this.trailing,
    this.large = false,
  });

  final String title;
  final String subtitle;
  final Piece piece;
  final Color accent;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final pieceSize = large ? 110.0 : 74.0;
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderColor: accent.withValues(alpha: 0.35),
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.04),
        ],
      ),
      child: SizedBox(
        height: large ? 150 : 172,
        child: Stack(
          children: [
            PositionedDirectional(
              end: large ? 8 : -6,
              bottom: large ? 4 : -8,
              child: Opacity(
                opacity: large ? 1 : 0.9,
                child: SizedBox.square(
                  dimension: pieceSize,
                  child: PieceView(piece: piece, style: PieceStyle.royal),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                16,
                16,
                large ? pieceSize + 8 : 16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: large ? 21 : 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (trailing != null) ...[const Spacer(), trailing!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
