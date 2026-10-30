import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/chess_ui/chess_board_view.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/utils/game_feedback.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../core/widgets/royal_button.dart';
import '../../../engine/chess_engine.dart';
import '../../game/presentation/widgets/game_dialogs.dart';
import '../../progress/domain/reward_rules.dart';
import '../../progress/presentation/achievement_style.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_catalog.dart';
import 'puzzle_cubit.dart';

/// Solving one puzzle.
class PuzzlePage extends StatelessWidget {
  const PuzzlePage({super.key, required this.puzzle});

  final Puzzle puzzle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PuzzleCubit(puzzle),
      child: const _PuzzleView(),
    );
  }
}

class _PuzzleView extends StatefulWidget {
  const _PuzzleView();

  @override
  State<_PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<_PuzzleView> {
  /// What solving earned; null until solved or when nothing was new.
  GameRewards? _rewards;

  void _onSolved(PuzzleState state) {
    final puzzle = state.puzzle;
    final rewards = context.read<ProgressCubit>().solvePuzzle(
      puzzle.id,
      coins: puzzle.coins,
      xp: puzzle.xp,
      isDaily: PuzzleCatalog.daily(DateTime.now()).id == puzzle.id,
      totalPuzzles: PuzzleCatalog.puzzles.length,
    );
    setState(() => _rewards = rewards);
  }

  /// The next unsolved puzzle after [current], wrapping around.
  Puzzle? _nextPuzzle(Puzzle current) {
    final solved = context.read<ProgressCubit>().state.solvedPuzzles;
    final puzzles = PuzzleCatalog.puzzles;
    final index = puzzles.indexWhere((p) => p.id == current.id);
    for (var i = 1; i < puzzles.length; i++) {
      final candidate = puzzles[(index + i) % puzzles.length];
      if (!solved.contains(candidate.id)) return candidate;
    }
    return index + 1 < puzzles.length ? puzzles[index + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    return MultiBlocListener(
      listeners: [
        BlocListener<PuzzleCubit, PuzzleState>(
          listenWhen: (a, b) =>
              a.feedbackSerial != b.feedbackSerial ||
              a.moveCount != b.moveCount,
          listener: (context, state) {
            if (state.feedback == PuzzleFeedback.wrong) {
              GameFeedback.alert(settings);
            } else {
              GameFeedback.move(
                settings,
                capture: state.lastMove?.isCapture ?? false,
              );
            }
          },
        ),
        BlocListener<PuzzleCubit, PuzzleState>(
          listenWhen: (a, b) => !a.solved && b.solved,
          listener: (context, state) => _onSolved(state),
        ),
        BlocListener<PuzzleCubit, PuzzleState>(
          listenWhen: (a, b) =>
              a.promotionSquares == null && b.promotionSquares != null,
          listener: (context, state) async {
            final cubit = context.read<PuzzleCubit>();
            final type = await showPromotionPicker(
              context,
              state.solverColor,
              PieceStyle.byId(settings.pieceStyleId),
            );
            cubit.choosePromotion(type);
          },
        ),
      ],
      child: BlocBuilder<PuzzleCubit, PuzzleState>(
        builder: (context, state) {
          final cubit = context.read<PuzzleCubit>();
          final puzzle = state.puzzle;
          final number = PuzzleCatalog.puzzles.indexOf(puzzle) + 1;
          final next = state.solved ? _nextPuzzle(puzzle) : null;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(title: Text(s.puzzleNumber(number))),
            body: RoyalBackground(
              glow: false,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: [
                        _InstructionCard(puzzle: puzzle, state: state),
                        const SizedBox(height: 12),
                        ChessBoardView(
                          pieces: state.pieces,
                          boardTheme: BoardTheme.byId(settings.boardThemeId),
                          pieceStyle: PieceStyle.byId(settings.pieceStyleId),
                          flipped: state.solverColor == PieceColor.black,
                          selectedSquare: state.selectedSquare,
                          targetMoves: state.selectedMoves,
                          lastMove: state.lastMove,
                          moveCount: state.moveCount,
                          showCoordinates: settings.showCoordinates,
                          movableColor: state.canMove
                              ? state.solverColor
                              : null,
                          marks: [
                            if (state.hintSquare case final square?)
                              SquareMark(square, SquareMarkKind.goal),
                          ],
                          onSquareTap: cubit.tapSquare,
                          onDragStart: cubit.startDrag,
                          onMove: cubit.dropPiece,
                        ),
                        const SizedBox(height: 14),
                        _FeedbackBanner(state: state),
                        if (state.solved && _rewards != null) ...[
                          const SizedBox(height: 10),
                          _RewardsRow(rewards: _rewards!),
                        ],
                        const SizedBox(height: 12),
                        if (state.solved) ...[
                          if (next != null)
                            RoyalButton(
                              label: s.nextPuzzle,
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () => AppRoutes.replace(
                                context,
                                PuzzlePage(puzzle: next),
                              ),
                            ),
                          const SizedBox(height: 8),
                          GhostButton(
                            label: s.close,
                            icon: Icons.check_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: GhostButton(
                                  label: s.hint,
                                  icon: Icons.lightbulb_rounded,
                                  onPressed: state.canMove
                                      ? cubit.showHint
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GhostButton(
                                  label: s.startOver,
                                  icon: Icons.refresh_rounded,
                                  onPressed: cubit.restart,
                                ),
                              ),
                            ],
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
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.puzzle, required this.state});

  final Puzzle puzzle;
  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: palette.surface.withValues(alpha: 0.85),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.extension_rounded, color: palette.accentLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.puzzleInstruction(state.solverColor, puzzle.theme.name),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StarRow(stars: puzzle.difficulty, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      s.puzzleDifficulty(puzzle.difficulty),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.state});

  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final (String? text, Color color, IconData icon) = switch (state.feedback) {
      PuzzleFeedback.solved => (
        s.puzzleSolved,
        AppColors.emerald,
        Icons.emoji_events_rounded,
      ),
      PuzzleFeedback.correct => (
        s.puzzleKeepGoing,
        AppColors.sapphire,
        Icons.check_circle_rounded,
      ),
      PuzzleFeedback.wrong => (
        s.puzzleWrong,
        AppColors.ruby,
        Icons.replay_circle_filled_rounded,
      ),
      PuzzleFeedback.none when state.hintSquare != null => (
        s.puzzleHintLabel,
        AppColors.emerald,
        Icons.lightbulb_rounded,
      ),
      PuzzleFeedback.none => (null, AppColors.textMuted, Icons.circle),
    };
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

class _RewardsRow extends StatelessWidget {
  const _RewardsRow({required this.rewards});

  final GameRewards rewards;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (rewards.xp > 0) ...[
              const Icon(Icons.auto_graph_rounded, color: AppColors.emerald),
              const SizedBox(width: 6),
              Text(
                s.xpGained(rewards.xp),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 18),
            ],
            const CoinIcon(size: 20),
            const SizedBox(width: 6),
            Text(
              s.coinsGained(rewards.coins),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        for (final achievement in rewards.newAchievements)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${s.newAchievement}: ${s.achievementTitle(achievement)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: achievement.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
