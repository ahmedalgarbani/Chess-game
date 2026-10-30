import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../progress/domain/reward_rules.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_catalog.dart';
import 'puzzle_page.dart';

/// The puzzle of the day and every puzzle of the catalogue.
class PuzzlesPage extends StatelessWidget {
  const PuzzlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final progress = context.watch<ProgressCubit>().state;
    final solved = progress.solvedPuzzles;
    final puzzles = PuzzleCatalog.puzzles;
    final now = DateTime.now();
    final daily = PuzzleCatalog.daily(now);
    final solvedCount = puzzles.where((p) => solved.contains(p.id)).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(s.puzzlesTitle)),
      body: RoyalBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                sliver: SliverList.list(
                  children: [
                    Text(
                      s.puzzlesSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    GoldProgressBar(value: solvedCount / puzzles.length),
                    const SizedBox(height: 4),
                    Text(
                      s.modePuzzlesSubtitle(solvedCount, puzzles.length),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    DailyPuzzleCard(
                      puzzle: daily,
                      done: progress.solvedDailyPuzzle(now),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: puzzles.length,
                  itemBuilder: (context, index) => _PuzzleTile(
                    number: index + 1,
                    puzzle: puzzles[index],
                    solved: solved.contains(puzzles[index].id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The puzzle of the day, shown on the puzzles and home screens.
class DailyPuzzleCard extends StatelessWidget {
  const DailyPuzzleCard({super.key, required this.puzzle, required this.done});

  final Puzzle puzzle;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    const color = AppColors.sapphire;
    return GlassCard(
      onTap: () => AppRoutes.push(context, PuzzlePage(puzzle: puzzle)),
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.6),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.06)],
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.task_alt_rounded : Icons.extension_rounded,
            color: color,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.dailyPuzzleTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${s.puzzleThemeName(puzzle.theme.name)} · '
                  '${s.puzzleDifficulty(puzzle.difficulty)}',
                  style: TextStyle(
                    color: context.palette.accentLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  done
                      ? s.dailyPuzzleDone
                      : s.dailyPuzzleBody(RewardRules.dailyPuzzleBonus),
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

class _PuzzleTile extends StatelessWidget {
  const _PuzzleTile({
    required this.number,
    required this.puzzle,
    required this.solved,
  });

  final int number;
  final Puzzle puzzle;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    return GlassCard(
      onTap: () => AppRoutes.push(context, PuzzlePage(puzzle: puzzle)),
      padding: const EdgeInsets.all(12),
      borderColor: solved ? AppColors.emerald.withValues(alpha: 0.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                s.puzzleNumber(number),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (solved)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.emerald,
                  size: 20,
                ),
            ],
          ),
          const Spacer(),
          Text(
            s.puzzleThemeName(puzzle.theme.name),
            style: TextStyle(
              color: palette.accentLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              StarRow(stars: puzzle.difficulty, size: 15),
              const Spacer(),
              const CoinIcon(size: 14),
              const SizedBox(width: 3),
              Text(
                '${puzzle.coins}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.accentLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
