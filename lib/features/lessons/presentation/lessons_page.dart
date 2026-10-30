import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/chess_ui/piece_painter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../engine/chess_engine.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../domain/lesson_catalog.dart';
import 'lesson_page.dart';

/// The list of lessons, in the recommended order.
class LessonsPage extends StatelessWidget {
  const LessonsPage({super.key, this.welcome = false});

  /// Shown right after onboarding for beginners.
  final bool welcome;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final completed = context.watch<ProgressCubit>().state.completedLessons;
    final lessons = LessonCatalog.lessons;
    final nextIndex = lessons.indexWhere(
      (lesson) => !completed.contains(lesson.id),
    );
    final arabic = s.isArabic;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(s.lessonsTitle)),
      body: RoyalBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassCard(
                gradient: LinearGradient(
                  colors: [
                    AppColors.amethyst.withValues(alpha: 0.28),
                    AppColors.amethyst.withValues(alpha: 0.06),
                  ],
                ),
                borderColor: AppColors.amethyst.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: AppColors.amethyst,
                      size: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            welcome ? s.welcomeTitle : s.lessonsTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.lessonsSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          GoldProgressBar(
                            value: completed.length / lessons.length,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.modeLearnSubtitle(
                              completed.length,
                              lessons.length,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final (index, lesson) in lessons.indexed) ...[
                _LessonTile(
                  number: index + 1,
                  title: lesson.title.resolve(arabic: arabic),
                  summary: lesson.summary.resolve(arabic: arabic),
                  icon: lesson.icon,
                  done: completed.contains(lesson.id),
                  current: index == nextIndex,
                  onTap: () =>
                      AppRoutes.push(context, LessonPage(lesson: lesson)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.number,
    required this.title,
    required this.summary,
    required this.icon,
    required this.done,
    required this.current,
    required this.onTap,
  });

  final int number;
  final String title;
  final String summary;
  final PieceType icon;
  final bool done;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: current
          ? AppColors.gold
          : done
          ? AppColors.emerald.withValues(alpha: 0.5)
          : null,
      gradient: current
          ? LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.2),
                AppColors.gold.withValues(alpha: 0.04),
              ],
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceHigh,
              border: Border.all(
                color: done ? AppColors.emerald : AppColors.outline,
                width: 2,
              ),
            ),
            child: PieceView(
              piece: Piece(PieceColor.white, icon),
              style: PieceStyle.royal,
              shadow: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(summary, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            Tooltip(
              message: s.completed,
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.emerald,
              ),
            )
          else
            Icon(
              current
                  ? Icons.play_circle_fill_rounded
                  : Icons.chevron_right_rounded,
              color: current ? AppColors.gold : AppColors.textMuted,
              size: current ? 30 : 24,
            ),
        ],
      ),
    );
  }
}
