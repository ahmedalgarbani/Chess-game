import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes.dart';
import '../../../../core/chess_ui/chess_board_view.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../../core/utils/game_feedback.dart';
import '../../../../core/widgets/royal_background.dart';
import '../../../../core/widgets/royal_button.dart';
import '../../../../engine/chess_engine.dart';
import '../../../progress/domain/reward_rules.dart';
import '../../../progress/presentation/progress_cubit.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/settings_cubit.dart';
import '../../../settings/presentation/settings_page.dart';
import '../../domain/ai_level.dart';
import '../../domain/chess_ai_service.dart';
import '../../domain/game_config.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';
import '../widgets/coach_panel.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/game_over_sheet.dart';
import '../widgets/move_history_strip.dart';
import '../widgets/player_panel.dart';
import '../widgets/prediction_panel.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key, required this.config});

  final GameConfig config;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameCubit(
        config: config,
        ai: context.read<ChessAiService>(),
        settings: context.read<SettingsCubit>().state,
      )..start(),
      child: const _GameView(),
    );
  }
}

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  GameRewards? _lastRewards;
  String? _reaction;
  int _reactionKey = 0;

  GameCubit get _cubit => context.read<GameCubit>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, AppSettings>(
          listener: (context, settings) => _cubit.updateSettings(settings),
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) => b.moveCount > a.moveCount,
          listener: (context, state) => GameFeedback.move(
            context.read<SettingsCubit>().state,
            capture: state.lastMove?.isCapture ?? false,
            check: state.checkSquare != null,
          ),
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) =>
              a.pendingPromotion == null && b.pendingPromotion != null,
          listener: _onPromotion,
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) =>
              a.pendingRisky == null && b.pendingRisky != null,
          listener: _onRiskyMove,
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) => a.outcome == null && b.outcome != null,
          listener: _onGameOver,
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) =>
              a.event?.serial != b.event?.serial && b.event != null,
          listener: _onEvent,
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) =>
              !a.drawOfferedByOpponent && b.drawOfferedByOpponent,
          listener: _onDrawOffer,
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (a, b) =>
              !a.rematchOfferedByOpponent && b.rematchOfferedByOpponent,
          listener: _onRematchOffer,
        ),
      ],
      child: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          final canLeave = state.isOver || state.moveCount == 0;
          return PopScope(
            canPop: canLeave,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _confirmLeave();
            },
            child: Scaffold(
              body: RoyalBackground(
                glow: false,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: _GameLayout(
                            state: state,
                            onLeave: _confirmLeave,
                            onShowResult: _showResultAgain,
                          ),
                        ),
                      ),
                      if (_reaction != null)
                        _ReactionBurst(
                          key: ValueKey(_reactionKey),
                          emoji: _reaction!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final s = context.s;
    if (_cubit.state.isOver || _cubit.state.moveCount == 0) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await confirm(
      context,
      title: s.confirmLeaveTitle,
      body: s.confirmLeaveBody,
      confirmLabel: s.leave,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  Future<void> _onPromotion(BuildContext context, GameState state) async {
    final pending = state.pendingPromotion!;
    final style = PieceStyle.byId(
      context.read<SettingsCubit>().state.pieceStyleId,
    );
    final type = await showPromotionPicker(context, pending.color, style);
    if (!mounted) return;
    if (type == null) {
      _cubit.cancelPromotion();
    } else {
      _cubit.choosePromotion(type);
    }
  }

  Future<void> _onRiskyMove(BuildContext context, GameState state) async {
    GameFeedback.alert(context.read<SettingsCubit>().state);
    final playAnyway = await showRiskyMoveDialog(context, state.pendingRisky!);
    if (!mounted) return;
    if (playAnyway) {
      _cubit.confirmRiskyMove();
    } else {
      _cubit.cancelRiskyMove();
    }
  }

  Future<void> _onGameOver(BuildContext context, GameState state) async {
    final summary = _cubit.summary();
    _lastRewards = summary == null
        ? null
        : context.read<ProgressCubit>().recordGame(summary);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await _showResultAgain();
  }

  Future<void> _showResultAgain() async {
    final state = _cubit.state;
    final outcome = state.outcome;
    if (outcome == null) return;
    final action = await showGameOverSheet(
      context,
      outcome: outcome,
      config: _cubit.config,
      rewards: _lastRewards,
    );
    if (!mounted) return;
    switch (action) {
      case GameOverAction.playAgain:
        _cubit.restart();
      case GameOverAction.nextLevel:
        final config = _cubit.config;
        final next = AiLevel.byNumber((config.aiLevel?.number ?? 1) + 1);
        final s = context.s;
        final player = config.playerColor;
        final me = player == PieceColor.white
            ? config.whiteName
            : config.blackName;
        final computer = s.aiLevelName(next.number);
        AppRoutes.replace(
          context,
          GamePage(
            config: GameConfig(
              mode: GameMode.computer,
              playerColor: player,
              aiLevel: next,
              timeControl: config.timeControl,
              whiteName: player == PieceColor.white ? me : computer,
              blackName: player == PieceColor.white ? computer : me,
              ladder: config.ladder,
            ),
          ),
        );
      case GameOverAction.rematch:
        _cubit.offerRematch();
      case GameOverAction.home:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case GameOverAction.viewBoard || null:
        break;
    }
  }

  void _onEvent(BuildContext context, GameState state) {
    final event = state.event!;
    final s = context.s;
    final message = switch (event.kind) {
      GameEventKind.drawDeclined => s.drawDeclined,
      GameEventKind.rematchDeclined => s.rematchDeclined,
      GameEventKind.hintLimitReached => s.hintLimitReached,
      GameEventKind.opponentLeft => s.opponentLeft,
      GameEventKind.drawOffered || GameEventKind.reaction => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
    if (event.kind == GameEventKind.reaction && event.payload != null) {
      setState(() {
        _reaction = event.payload;
        _reactionKey++;
      });
    }
  }

  Future<void> _onDrawOffer(BuildContext context, GameState state) async {
    final s = context.s;
    final accept = await confirm(
      context,
      title: s.opponentOffersDraw,
      confirmLabel: s.accept,
    );
    if (mounted) _cubit.answerDrawOffer(accept: accept);
  }

  Future<void> _onRematchOffer(BuildContext context, GameState state) async {
    final s = context.s;
    final navigator = Navigator.of(context);
    final accept = await confirm(
      context,
      title: s.rematchOffered,
      confirmLabel: s.accept,
    );
    if (!mounted) return;
    if (accept) {
      // Close the result sheet if it is still open.
      navigator.popUntil((route) => route is! ModalBottomSheetRoute);
    }
    _cubit.answerRematch(accept: accept);
  }
}

class _GameLayout extends StatelessWidget {
  const _GameLayout({
    required this.state,
    required this.onLeave,
    required this.onShowResult,
  });

  final GameState state;
  final VoidCallback onLeave;
  final VoidCallback onShowResult;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<GameCubit>();
    final config = state.config;
    final lan = config.mode == GameMode.lan;
    final predictions = settings.showPredictions && !lan;
    final boardTheme = BoardTheme.byId(settings.boardThemeId);
    final pieceStyle = PieceStyle.byId(settings.pieceStyleId);

    final bottomColor = state.flipped ? PieceColor.black : PieceColor.white;
    final topColor = bottomColor.opposite;
    final localTurn = config.controlsColor(state.turn) && !state.isOver;
    final analysis = predictions ? state.analysis : null;

    final arrows = <BoardArrow>[
      if (analysis != null) ...[
        for (final (index, uci) in analysis.principalVariation.take(2).indexed)
          _arrow(
            uci,
            index == 0 ? AppColors.sapphire : AppColors.amethyst,
            '${index + 1}',
          ),
        if (analysis.threat != null && localTurn)
          _arrow(analysis.threat!, AppColors.ruby, '!'),
      ],
      if (state.hint != null)
        BoardArrow(
          from: state.hint!.move.from,
          to: state.hint!.move.to,
          color: AppColors.emerald,
        ),
    ];

    final threatSan = analysis != null && localTurn ? state.threatSan : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final reserved = 330.0 + (predictions ? 18 : 0);
        final boardSize = min(
          constraints.maxWidth - 16,
          max(220.0, constraints.maxHeight - reserved),
        ).toDouble();
        final infoNotes = state.coachNotes;
        final showCoach = infoNotes.isNotEmpty;

        Widget panel(PieceColor color) => PlayerPanel(
          name: _nameOf(s, config, color),
          subtitle: _subtitleOf(s, config, color),
          color: color,
          captured: state.capturedBy(color),
          advantage: state.materialBalance * color.sign,
          active: state.turn == color && !state.isOver,
          pieceStyle: pieceStyle,
          clock: config.timeControl == null ? null : cubit.clockReading,
          thinking: state.aiThinking && state.turn == color,
        );

        return Column(
          children: [
            _TopBar(state: state, onBack: onLeave, onShowResult: onShowResult),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: panel(topColor),
            ),
            const SizedBox(height: 8),
            if (predictions)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: EvaluationBar(analysis: state.analysis),
              ),
            SizedBox.square(
              dimension: boardSize,
              child: ChessBoardView(
                pieces: state.pieces,
                boardTheme: boardTheme,
                pieceStyle: pieceStyle,
                flipped: state.flipped,
                selectedSquare: state.selectedSquare,
                targetMoves: state.selectedMoves,
                lastMove: state.lastMove,
                checkSquare: state.checkSquare,
                marks: [
                  for (final square in state.dangerSquares)
                    SquareMark(square, SquareMarkKind.danger),
                ],
                arrows: arrows,
                movableColor: localTurn && !state.aiThinking
                    ? state.turn
                    : null,
                showCoordinates: settings.showCoordinates,
                showLegalMoves: settings.showLegalMoves,
                moveCount: state.moveCount,
                onSquareTap: (square) {
                  GameFeedback.tap(settings);
                  cubit.tapSquare(square);
                },
                onDragStart: cubit.startDrag,
                onMove: cubit.dropPiece,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: panel(bottomColor),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MoveHistoryStrip(history: state.history),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (state.reviewingMove || state.hintLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: AppColors.gold,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    if (predictions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PredictionPanel(
                          analysis: state.analysis,
                          predictedLine: state.predictedLine,
                          threatSan: threatSan,
                        ),
                      ),
                    if (showCoach)
                      SizedBox(
                        height: 220,
                        child: CoachPanel(notes: infoNotes),
                      ),
                  ],
                ),
              ),
            ),
            _ActionBar(state: state, predictions: predictions),
          ],
        );
      },
    );
  }

  static BoardArrow _arrow(String uci, Color color, String label) => BoardArrow(
    from: Square.parse(uci.substring(0, 2)),
    to: Square.parse(uci.substring(2, 4)),
    color: color,
    label: label,
  );

  static String _nameOf(AppStrings s, GameConfig config, PieceColor color) {
    final name = color == PieceColor.white
        ? config.whiteName
        : config.blackName;
    return (name == null || name.isEmpty) ? s.colorName(color) : name;
  }

  static String? _subtitleOf(
    AppStrings s,
    GameConfig config,
    PieceColor color,
  ) {
    final level = config.aiLevel;
    if (config.mode == GameMode.computer &&
        level != null &&
        color != config.playerColor) {
      return '${s.levelLabel(level.number)} · ${level.approxRating}';
    }
    return s.colorName(color);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.onBack,
    required this.onShowResult,
  });

  final GameState state;
  final VoidCallback onBack;
  final VoidCallback onShowResult;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final config = state.config;
    final title = switch (config.mode) {
      GameMode.computer => s.aiLevelName(config.aiLevel?.number ?? 1),
      GameMode.local => s.modeLocal,
      GameMode.lan => s.lanTitle,
    };
    final (statusText, statusColor) = state.isOver
        ? (s.outcomeReason(state.outcome!.reason), AppColors.textSecondary)
        : state.checkSquare != null
        ? (s.check, AppColors.ruby)
        : config.controlsColor(state.turn) && config.mode != GameMode.local
        ? (s.yourTurn, AppColors.emerald)
        : (s.turnOf(state.turn), AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            size: 42,
            onPressed: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.isOver)
            TextButton.icon(
              onPressed: onShowResult,
              icon: const Icon(Icons.emoji_events_rounded),
              label: Text(s.rewards),
              style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            ),
          CircleIconButton(
            icon: Icons.tune_rounded,
            size: 42,
            tooltip: s.settings,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7,
                maxChildSize: 0.92,
                builder: (context, controller) => ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: const [AssistanceSettings()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state, required this.predictions});

  final GameState state;
  final bool predictions;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<GameCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    final lan = state.config.mode == GameMode.lan;
    final over = state.isOver;
    final localTurn = state.config.controlsColor(state.turn) && !over;
    final hintsLeft = cubit.hintsLeft;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          if (!lan)
            _ActionButton(
              icon: Icons.lightbulb_rounded,
              label: s.hint,
              color: AppColors.emerald,
              badge: hintsLeft < 0 ? '∞' : '$hintsLeft',
              onTap: localTurn && !state.aiThinking ? cubit.requestHint : null,
            ),
          if (!lan)
            _ActionButton(
              icon: Icons.undo_rounded,
              label: s.undo,
              onTap: state.canUndo ? cubit.undo : null,
            ),
          if (!lan)
            _ActionButton(
              icon: Icons.auto_awesome_rounded,
              label: s.predictions,
              color: predictions ? AppColors.sapphire : null,
              onTap: () => settingsCubit.update(
                (s) => s.copyWith(showPredictions: !s.showPredictions),
              ),
            ),
          if (lan)
            _ActionButton(
              icon: Icons.emoji_emotions_rounded,
              label: s.reactions,
              onTap: () => _showReactions(context),
            ),
          _ActionButton(
            icon: Icons.swap_vert_rounded,
            label: s.flip,
            onTap: cubit.flipBoard,
          ),
          _ActionButton(
            icon: Icons.handshake_rounded,
            label: s.offerDraw,
            onTap: over || state.drawOfferPending
                ? null
                : () => _offerDraw(context),
          ),
          _ActionButton(
            icon: Icons.flag_rounded,
            label: s.resign,
            color: AppColors.ruby,
            onTap: over ? null : () => _resign(context),
          ),
        ],
      ),
    );
  }

  Future<void> _resign(BuildContext context) async {
    final s = context.s;
    final cubit = context.read<GameCubit>();
    final ok = await confirm(
      context,
      title: s.confirmResignTitle,
      body: s.confirmResignBody,
      confirmLabel: s.resign,
    );
    if (ok) cubit.resign();
  }

  Future<void> _offerDraw(BuildContext context) async {
    final s = context.s;
    final cubit = context.read<GameCubit>();
    if (state.config.mode == GameMode.local) {
      final ok = await confirm(context, title: s.confirmDrawTitle);
      if (ok) cubit.offerDraw();
      return;
    }
    if (state.config.mode == GameMode.lan) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.drawOfferSent)));
    }
    cubit.offerDraw();
  }

  void _showReactions(BuildContext context) {
    final cubit = context.read<GameCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final emoji in const [
                '👍',
                '😮',
                '😂',
                '🔥',
                '🤝',
                '😅',
                '👑',
                '💪',
              ])
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    cubit.sendReaction(emoji);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(emoji, style: const TextStyle(fontSize: 34)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tint = enabled
        ? (color ?? AppColors.textPrimary)
        : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge != null,
                label: Text(badge ?? ''),
                backgroundColor: AppColors.gold,
                textColor: AppColors.background,
                child: Icon(icon, color: tint, size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A big emoji that floats up when the opponent reacts.
class _ReactionBurst extends StatelessWidget {
  const _ReactionBurst({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2200),
        builder: (context, t, child) {
          final opacity = t < 0.15
              ? t / 0.15
              : (t > 0.75 ? (1 - t) / 0.25 : 1.0);
          return Align(
            alignment: Alignment(0, 0.2 - t * 0.6),
            child: Opacity(
              opacity: opacity.clamp(0, 1),
              child: Transform.scale(
                scale: 0.6 + Curves.elasticOut.transform(min(1, t * 2)) * 0.8,
                child: child,
              ),
            ),
          );
        },
        child: Text(emoji, style: const TextStyle(fontSize: 72)),
      ),
    );
  }
}
