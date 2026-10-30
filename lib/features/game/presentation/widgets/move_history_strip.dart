import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../engine/chess_engine.dart';

/// A horizontally scrolling list of the moves played, newest visible.
class MoveHistoryStrip extends StatefulWidget {
  const MoveHistoryStrip({super.key, required this.history});

  final List<MoveRecord> history;

  @override
  State<MoveHistoryStrip> createState() => _MoveHistoryStripState();
}

class _MoveHistoryStripState extends State<MoveHistoryStrip> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(MoveHistoryStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length != oldWidget.history.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final pairs = <(int, String, String?)>[];
    for (final record in history) {
      if (record.color == PieceColor.white || pairs.isEmpty) {
        if (record.color == PieceColor.black) {
          pairs.add((record.moveNumber, '…', record.san));
        } else {
          pairs.add((record.moveNumber, record.san, null));
        }
      } else {
        final last = pairs.removeLast();
        pairs.add((last.$1, last.$2, record.san));
      }
    }
    return SizedBox(
      height: 34,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          itemCount: pairs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final palette = context.palette;
            final (number, white, black) = pairs[index];
            final isLast = index == pairs.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isLast
                    ? palette.accent.withValues(alpha: 0.16)
                    : AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLast ? palette.accent : palette.outline,
                ),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$number. ',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    TextSpan(text: white),
                    if (black != null) TextSpan(text: '  $black'),
                  ],
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
