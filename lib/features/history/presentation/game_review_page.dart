import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/chess_ui/chess_board_view.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../core/widgets/royal_button.dart';
import '../../../engine/chess_ai.dart';
import '../../../engine/chess_engine.dart';
import '../../game/domain/chess_ai_service.dart';
import '../../game/presentation/widgets/prediction_panel.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/game_record.dart';
import '../domain/game_replay.dart';
import 'game_record_tile.dart';

/// Steps through a finished game, with engine analysis on demand.
class GameReviewPage extends StatefulWidget {
  const GameReviewPage({super.key, required this.record});

  final GameRecord record;

  @override
  State<GameReviewPage> createState() => _GameReviewPageState();
}

class _GameReviewPageState extends State<GameReviewPage> {
  late final GameReplay _replay = GameReplay(widget.record.moves);
  late int _ply = _replay.length;
  bool _flipped = false;

  /// Analysis of the position at [_analysisPly].
  PositionAnalysis? _analysis;
  int? _analysisPly;
  bool _analyzing = false;

  void _goTo(int ply) {
    setState(() => _ply = ply.clamp(0, _replay.length));
  }

  Future<void> _analyze() async {
    final ply = _ply;
    setState(() => _analyzing = true);
    PositionAnalysis? analysis;
    try {
      analysis = await context.read<ChessAiService>().analyze(
        PositionSnapshot(startingFen, _replay.uciUpTo(ply)),
      );
    } on Object {
      analysis = null;
    }
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _analysis = analysis;
      _analysisPly = analysis == null ? null : ply;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final settings = context.watch<SettingsCubit>().state;
    final record = widget.record;
    final analysis = _analysisPly == _ply ? _analysis : null;
    final best = analysis?.bestMove;
    final bestMove = best == null
        ? null
        : ChessGame.fromMoves(_replay.uciUpTo(_ply)).moveFromUci(best);
    final bestSan = bestMove == null
        ? null
        : ChessGame.fromMoves(_replay.uciUpTo(_ply)).sanOf(bestMove);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(s.reviewTitle),
        actions: [
          IconButton(
            tooltip: s.flip,
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: () => setState(() => _flipped = !_flipped),
          ),
        ],
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
                  GameRecordTile(record: record),
                  const SizedBox(height: 10),
                  ChessBoardView(
                    pieces: _replay.positions[_ply],
                    boardTheme: BoardTheme.byId(settings.boardThemeId),
                    pieceStyle: PieceStyle.byId(settings.pieceStyleId),
                    flipped:
                        (record.playerColor == PieceColor.black) != _flipped,
                    lastMove: _ply == 0 ? null : _replay.moves[_ply - 1],
                    checkSquare: _replay.checks[_ply],
                    moveCount: _ply,
                    showCoordinates: settings.showCoordinates,
                    arrows: [
                      if (bestMove != null)
                        BoardArrow(
                          from: bestMove.from,
                          to: bestMove.to,
                          color: AppColors.emerald,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Controls(ply: _ply, length: _replay.length, onGoTo: _goTo),
                  const SizedBox(height: 10),
                  _MoveList(
                    sans: _replay.sans,
                    ply: _ply,
                    onSelect: (ply) => _goTo(ply),
                  ),
                  const SizedBox(height: 12),
                  if (analysis != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evaluationText(s, analysis),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: palette.accentLight,
                            ),
                          ),
                          if (bestSan != null)
                            Text(
                              s.bestMoveIs(bestSan),
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    GhostButton(
                      label: _analyzing ? s.analyzing : s.analyzePosition,
                      icon: Icons.insights_rounded,
                      onPressed: _analyzing ? null : _analyze,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.ply,
    required this.length,
    required this.onGoTo,
  });

  final int ply;
  final int length;
  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    // These icons mirror themselves in right-to-left layouts.
    Widget button(IconData icon, int target, bool enabled) =>
        IconButton.filledTonal(
          onPressed: enabled ? () => onGoTo(target) : null,
          icon: Icon(icon),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        button(Icons.first_page_rounded, 0, ply > 0),
        button(Icons.chevron_left_rounded, ply - 1, ply > 0),
        Text(
          s.moveOf(ply, length),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: palette.accentLight,
          ),
        ),
        button(Icons.chevron_right_rounded, ply + 1, ply < length),
        button(Icons.last_page_rounded, length, ply < length),
      ],
    );
  }
}

class _MoveList extends StatelessWidget {
  const _MoveList({
    required this.sans,
    required this.ply,
    required this.onSelect,
  });

  final List<String> sans;
  final int ply;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Directionality(
      // Chess notation reads left to right in every language.
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < sans.length; i++)
            GestureDetector(
              onTap: () => onSelect(i + 1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: i + 1 == ply
                      ? palette.accent.withValues(alpha: 0.25)
                      : AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i + 1 == ply ? palette.accent : palette.outline,
                  ),
                ),
                child: Text(
                  i.isEven ? '${i ~/ 2 + 1}. ${sans[i]}' : sans[i],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
