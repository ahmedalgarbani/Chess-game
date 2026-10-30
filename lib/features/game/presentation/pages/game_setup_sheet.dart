import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes.dart';
import '../../../../core/chess_ui/piece_painter.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/royal_button.dart';
import '../../../../engine/chess_engine.dart';
import '../../../progress/presentation/progress_cubit.dart';
import '../../../settings/presentation/settings_cubit.dart';
import '../../domain/ai_level.dart';
import '../../domain/game_config.dart';
import 'game_page.dart';

/// Colour preference, including a random draw.
enum ColorChoice { white, black, random }

extension ColorChoiceResolve on ColorChoice {
  PieceColor resolve([Random? random]) => switch (this) {
    ColorChoice.white => PieceColor.white,
    ColorChoice.black => PieceColor.black,
    ColorChoice.random =>
      (random ?? Random()).nextBool() ? PieceColor.white : PieceColor.black,
  };
}

/// Opens the setup sheet for a game against the computer. Without a
/// [level], the player can pick any unlocked level.
Future<void> showComputerGameSheet(
  BuildContext context, {
  AiLevel? level,
  bool ladder = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ComputerSetupSheet(fixedLevel: level, ladder: ladder),
  );
}

/// Opens the setup sheet for two players sharing one device.
Future<void> showLocalGameSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LocalSetupSheet(),
  );
}

class _ComputerSetupSheet extends StatefulWidget {
  const _ComputerSetupSheet({this.fixedLevel, required this.ladder});

  final AiLevel? fixedLevel;
  final bool ladder;

  @override
  State<_ComputerSetupSheet> createState() => _ComputerSetupSheetState();
}

class _ComputerSetupSheetState extends State<_ComputerSetupSheet> {
  ColorChoice _color = ColorChoice.white;
  TimeControl? _time;
  late int _level =
      widget.fixedLevel?.number ??
      context.read<ProgressCubit>().state.highestUnlockedLevel;

  void _start() {
    final level = AiLevel.byNumber(_level);
    final color = _color.resolve();
    final s = context.s;
    final name = context.read<SettingsCubit>().state.playerName;
    final me = name.isEmpty ? s.you : name;
    final computer = s.aiLevelName(level.number);
    final config = GameConfig(
      mode: GameMode.computer,
      playerColor: color,
      aiLevel: level,
      timeControl: _time,
      whiteName: color == PieceColor.white ? me : computer,
      blackName: color == PieceColor.white ? computer : me,
      ladder: widget.ladder,
    );
    Navigator.of(context).pop();
    AppRoutes.push(context, GamePage(config: config));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final progress = context.watch<ProgressCubit>().state;
    final level = AiLevel.byNumber(_level);
    return _SheetScaffold(
      children: [
        Row(
          children: [
            PieceMedallion(piece: _levelPiece(_level), size: 64, glow: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.levelLabel(level.number)} · ${s.aiLevelName(level.number)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.aiLevelDescription(level.number),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    s.approxRating(level.approxRating),
                    style: TextStyle(
                      color: palette.accentLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.fixedLevel == null) ...[
          const SizedBox(height: 18),
          SectionTitle(s.chooseLevel),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AiLevel.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final number = index + 1;
                final unlocked = progress.isLevelUnlocked(number);
                return ChoiceChip(
                  label: Text('$number'),
                  avatar: unlocked
                      ? null
                      : const Icon(Icons.lock_rounded, size: 16),
                  selected: number == _level,
                  onSelected: unlocked
                      ? (_) => setState(() => _level = number)
                      : null,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        SectionTitle(s.chooseColor),
        ColorChoiceSelector(
          value: _color,
          onChanged: (value) => setState(() => _color = value),
        ),
        const SizedBox(height: 18),
        SectionTitle(s.timeControl),
        TimeControlSelector(
          value: _time,
          onChanged: (value) => setState(() => _time = value),
        ),
        const SizedBox(height: 24),
        RoyalButton(
          label: s.startGame,
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }
}

/// The piece that represents a computer level.
Piece levelPiece(int level) => _levelPiece(level);

Piece _levelPiece(int level) => switch (level) {
  1 || 2 => Piece.whitePawn,
  3 => Piece.whiteKnight,
  4 => Piece.whiteBishop,
  5 => Piece.whiteRook,
  6 => Piece.whiteQueen,
  _ => Piece.whiteKing,
};

class _LocalSetupSheet extends StatefulWidget {
  const _LocalSetupSheet();

  @override
  State<_LocalSetupSheet> createState() => _LocalSetupSheetState();
}

class _LocalSetupSheetState extends State<_LocalSetupSheet> {
  final _white = TextEditingController();
  final _black = TextEditingController();
  TimeControl? _time;

  @override
  void dispose() {
    _white.dispose();
    _black.dispose();
    super.dispose();
  }

  void _start() {
    final s = context.s;
    final config = GameConfig(
      mode: GameMode.local,
      timeControl: _time,
      whiteName: _white.text.trim().isEmpty ? s.playerOne : _white.text.trim(),
      blackName: _black.text.trim().isEmpty ? s.playerTwo : _black.text.trim(),
    );
    Navigator.of(context).pop();
    AppRoutes.push(context, GamePage(config: config));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    return _SheetScaffold(
      children: [
        Text(s.localSetupTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _NameField(
          controller: _white,
          label: s.whitePlayerName,
          hint: s.playerOne,
          piece: Piece.whiteKing,
        ),
        const SizedBox(height: 12),
        _NameField(
          controller: _black,
          label: s.blackPlayerName,
          hint: s.playerTwo,
          piece: Piece.blackKing,
        ),
        const SizedBox(height: 18),
        SectionTitle(s.timeControl),
        TimeControlSelector(
          value: _time,
          onChanged: (value) => setState(() => _time = value),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            s.autoFlipBoard,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          value: settings.autoFlipBoard,
          onChanged: (value) => context.read<SettingsCubit>().update(
            (s) => s.copyWith(autoFlipBoard: value),
          ),
        ),
        const SizedBox(height: 16),
        RoyalButton(
          label: s.startGame,
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.piece,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Piece piece;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 16,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox.square(
            dimension: 28,
            child: PieceView(piece: piece, style: PieceStyle.royal),
          ),
        ),
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// White / black / random selector with piece icons.
class ColorChoiceSelector extends StatelessWidget {
  const ColorChoiceSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ColorChoice value;
  final ValueChanged<ColorChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    Widget option(ColorChoice choice, String label, Widget icon) {
      final selected = choice == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(choice),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? palette.accent.withValues(alpha: 0.18)
                  : AppColors.surfaceGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? palette.accent : palette.outline,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                SizedBox.square(dimension: 40, child: icon),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(
          ColorChoice.white,
          s.white,
          const PieceView(piece: Piece.whiteKing, style: PieceStyle.royal),
        ),
        const SizedBox(width: 10),
        option(
          ColorChoice.random,
          s.random,
          Icon(Icons.shuffle_rounded, color: palette.accentLight, size: 30),
        ),
        const SizedBox(width: 10),
        option(
          ColorChoice.black,
          s.black,
          const PieceView(piece: Piece.blackKing, style: PieceStyle.royal),
        ),
      ],
    );
  }
}

/// Chips for "no clock" and the clock presets.
class TimeControlSelector extends StatelessWidget {
  const TimeControlSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TimeControl? value;
  final ValueChanged<TimeControl?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(s.noTimer),
          avatar: const Icon(Icons.all_inclusive_rounded, size: 18),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final preset in TimeControl.presets)
          ChoiceChip(
            label: Text(
              preset.incrementSeconds == 0
                  ? s.minutes(preset.minutes)
                  : preset.label,
            ),
            avatar: const Icon(Icons.timer_outlined, size: 18),
            selected: value == preset,
            onSelected: (_) => onChanged(preset),
          ),
      ],
    );
  }
}
