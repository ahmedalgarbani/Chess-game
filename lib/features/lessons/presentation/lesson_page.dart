import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/chess_ui/chess_board_view.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/game_feedback.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../core/widgets/royal_button.dart';
import '../../../engine/chess_engine.dart';
import '../../game/domain/ai_level.dart';
import '../../game/domain/game_config.dart';
import '../../game/presentation/pages/game_page.dart';
import '../../game/presentation/widgets/game_dialogs.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/lesson.dart';
import '../domain/lesson_catalog.dart';
import 'lesson_cubit.dart';

class LessonPage extends StatelessWidget {
  const LessonPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LessonCubit(lesson),
      child: const _LessonView(),
    );
  }
}

class _LessonView extends StatelessWidget {
  const _LessonView();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    return MultiBlocListener(
      listeners: [
        BlocListener<LessonCubit, LessonState>(
          listenWhen: (a, b) => a.feedbackSerial != b.feedbackSerial,
          listener: (context, state) {
            if (state.feedback == LessonFeedback.wrong) {
              GameFeedback.alert(settings);
            } else {
              GameFeedback.move(
                settings,
                capture: state.lastMove?.isCapture ?? false,
              );
            }
          },
        ),
        BlocListener<LessonCubit, LessonState>(
          listenWhen: (a, b) =>
              a.promotionSquares == null && b.promotionSquares != null,
          listener: (context, state) async {
            final cubit = context.read<LessonCubit>();
            final type = await showPromotionPicker(
              context,
              state.learnerColor,
              PieceStyle.byId(settings.pieceStyleId),
            );
            cubit.choosePromotion(type);
          },
        ),
        BlocListener<LessonCubit, LessonState>(
          listenWhen: (a, b) => !a.completed && b.completed,
          listener: _onCompleted,
        ),
      ],
      child: BlocBuilder<LessonCubit, LessonState>(
        builder: (context, state) {
          final cubit = context.read<LessonCubit>();
          final step = state.step;
          final arabic = s.isArabic;
          final total = state.lesson.steps.length;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(state.lesson.title.resolve(arabic: arabic)),
            ),
            body: RoyalBackground(
              glow: false,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: [
                        Row(
                          children: [
                            Text(
                              s.lessonStep(state.stepIndex + 1, total),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GoldProgressBar(
                                value:
                                    (state.stepIndex +
                                        (state.stepSolved ? 1 : 0)) /
                                    total,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InstructionCard(
                          text: step.text.resolve(arabic: arabic),
                          starsLeft: state.stars.length,
                        ),
                        const SizedBox(height: 12),
                        ChessBoardView(
                          pieces: state.pieces,
                          boardTheme: BoardTheme.byId(settings.boardThemeId),
                          pieceStyle: PieceStyle.byId(settings.pieceStyleId),
                          flipped: state.learnerColor == PieceColor.black,
                          selectedSquare: state.selectedSquare,
                          targetMoves: state.selectedMoves,
                          lastMove: state.lastMove,
                          moveCount: state.moveCount,
                          showCoordinates: settings.showCoordinates,
                          movableColor: state.stepSolved
                              ? null
                              : state.learnerColor,
                          marks: [
                            for (final star in state.stars)
                              SquareMark(star, SquareMarkKind.star),
                            for (final name in step.highlights)
                              SquareMark(
                                Square.parse(name),
                                SquareMarkKind.info,
                              ),
                          ],
                          onSquareTap: cubit.tapSquare,
                          onDragStart: cubit.startDrag,
                          onMove: cubit.dropPiece,
                        ),
                        const SizedBox(height: 14),
                        _FeedbackBanner(state: state),
                        const SizedBox(height: 12),
                        if (state.stepSolved)
                          RoyalButton(
                            label: state.isLastStep
                                ? s.lessonCompleted
                                : s.nextStep,
                            icon: state.isLastStep
                                ? Icons.emoji_events_rounded
                                : Icons.arrow_forward_rounded,
                            onPressed: cubit.nextStep,
                          )
                        else
                          GhostButton(
                            label: s.restartStep,
                            icon: Icons.refresh_rounded,
                            onPressed: cubit.restartStep,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onCompleted(BuildContext context, LessonState state) async {
    final s = context.s;
    final rewards = context.read<ProgressCubit>().completeLesson(
      state.lesson.id,
      totalLessons: LessonCatalog.lessons.length,
    );
    final lessons = LessonCatalog.lessons;
    final index = lessons.indexWhere((l) => l.id == state.lesson.id);
    final next = index >= 0 && index < lessons.length - 1
        ? lessons[index + 1]
        : null;
    final navigator = Navigator.of(context);
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.emoji_events_rounded,
          color: AppColors.gold,
          size: 54,
        ),
        title: Text(s.lessonCompleted, textAlign: TextAlign.center),
        content: rewards == null
            ? Text(s.wellDone, textAlign: TextAlign.center)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_graph_rounded,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.xpGained(rewards.xp),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 18),
                  const CoinIcon(size: 20),
                  const SizedBox(width: 6),
                  Text(
                    s.coinsGained(rewards.coins),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              RoyalButton(
                label: next != null ? s.nextLesson : s.playFirstGame,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).pop('next'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop('back'),
                child: Text(s.close),
              ),
            ],
          ),
        ],
      ),
    );
    if (action == 'next') {
      if (next != null) {
        navigator.pushReplacement(AppRoutes.fade(LessonPage(lesson: next)));
      } else if (context.mounted) {
        final name = context.read<SettingsCubit>().state.playerName;
        final me = name.isEmpty ? s.you : name;
        navigator.pushReplacement(
          AppRoutes.fade(
            GamePage(
              config: GameConfig(
                mode: GameMode.computer,
                aiLevel: AiLevel.byNumber(1),
                whiteName: me,
                blackName: s.aiLevelName(1),
                ladder: true,
              ),
            ),
          ),
        );
      }
    } else {
      navigator.pop();
    }
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.text, required this.starsLeft});

  final String text;
  final int starsLeft;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface.withValues(alpha: 0.85),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.goldLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (starsLeft > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.s.starsLeft(starsLeft),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.state});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final solvedTask = state.stepSolved && state.step.goal != null;
    final (String? text, Color color, IconData icon) = solvedTask
        ? (s.wellDone, AppColors.emerald, Icons.check_circle_rounded)
        : state.feedback == LessonFeedback.wrong
        ? (s.tryAgain, AppColors.ruby, Icons.replay_circle_filled_rounded)
        : (null, AppColors.textMuted, Icons.circle);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: text == null
          ? const SizedBox(height: 0, key: ValueKey('empty'))
          : Container(
              key: ValueKey('${state.feedbackSerial}$text'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
