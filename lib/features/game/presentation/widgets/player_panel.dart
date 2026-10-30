import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/chess_ui/piece_painter.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../engine/chess_engine.dart';
import '../cubit/game_state.dart';

/// Name, captured pieces, material advantage and clock of one player.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.name,
    required this.color,
    required this.captured,
    required this.advantage,
    required this.active,
    required this.pieceStyle,
    this.subtitle,
    this.clock,
    this.thinking = false,
  });

  final String name;
  final PieceColor color;

  /// Opponent pieces this player has captured.
  final List<Piece> captured;

  /// Material advantage in pawns (only shown when positive).
  final int advantage;
  final bool active;
  final PieceStyle pieceStyle;
  final String? subtitle;

  /// Live clock readings; null when the game has no clock.
  final ValueListenable<ClockReading?>? clock;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final sorted = [...captured]
      ..sort((a, b) => b.type.value.compareTo(a.type.value));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: active
            ? AppColors.gold.withValues(alpha: 0.12)
            : AppColors.surfaceGlass,
        border: Border.all(
          color: active
              ? AppColors.gold.withValues(alpha: 0.6)
              : AppColors.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color == PieceColor.white
                  ? const Color(0xFFF4ECDD)
                  : const Color(0xFF1B2147),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: PieceView(
              piece: Piece(color, PieceType.king),
              style: pieceStyle,
              shadow: false,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(
                  height: 20,
                  child: thinking
                      ? _ThinkingLabel(text: context.s.thinking)
                      : Row(
                          children: [
                            Flexible(
                              child: _CapturedRow(
                                pieces: sorted,
                                style: pieceStyle,
                              ),
                            ),
                            if (advantage > 0)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 4,
                                ),
                                child: Text(
                                  '+$advantage',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (sorted.isEmpty && subtitle != null)
                              Flexible(
                                child: Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (clock != null)
            ValueListenableBuilder<ClockReading?>(
              valueListenable: clock!,
              builder: (context, reading, _) => reading == null
                  ? const SizedBox.shrink()
                  : _ClockBadge(
                      time: reading.of(color),
                      running: reading.running == color,
                    ),
            ),
        ],
      ),
    );
  }
}

class _CapturedRow extends StatelessWidget {
  const _CapturedRow({required this.pieces, required this.style});

  final List<Piece> pieces;
  final PieceStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final piece in pieces)
            Align(
              widthFactor: 0.62,
              child: SizedBox.square(
                dimension: 20,
                child: PieceView(piece: piece, style: style, shadow: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingLabel extends StatefulWidget {
  const _ThinkingLabel({required this.text});

  final String text;

  @override
  State<_ThinkingLabel> createState() => _ThinkingLabelState();
}

class _ThinkingLabelState extends State<_ThinkingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Row(
        children: [
          const Icon(
            Icons.psychology_rounded,
            size: 16,
            color: AppColors.goldLight,
          ),
          const SizedBox(width: 4),
          Text(
            widget.text,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockBadge extends StatelessWidget {
  const _ClockBadge({required this.time, required this.running});

  final Duration time;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final low = time < const Duration(seconds: 20);
    final background = running
        ? (low ? AppColors.ruby : AppColors.goldLight)
        : AppColors.surfaceHigh;
    final foreground = running
        ? (low ? Colors.white : const Color(0xFF2A1C02))
        : (low ? AppColors.ruby : AppColors.textSecondary);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (running)
            BoxShadow(
              color: background.withValues(alpha: 0.45),
              blurRadius: 14,
            ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: foreground),
            const SizedBox(width: 4),
            Text(
              formatClock(time),
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
