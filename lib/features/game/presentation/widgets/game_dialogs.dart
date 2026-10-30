import 'package:flutter/material.dart';

import '../../../../core/chess_ui/piece_painter.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/board_theme.dart';
import '../../../../core/widgets/royal_button.dart';
import '../../../../engine/chess_engine.dart';
import '../cubit/game_state.dart';

/// Lets the player pick the piece a pawn promotes to.
Future<PieceType?> showPromotionPicker(
  BuildContext context,
  PieceColor color,
  PieceStyle style,
) {
  return showDialog<PieceType>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.s.choosePromotion, textAlign: TextAlign.center),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in const [
            PieceType.queen,
            PieceType.rook,
            PieceType.bishop,
            PieceType.knight,
          ])
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pop(type),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: PieceView(
                          piece: Piece(color, type),
                          style: style,
                        ),
                      ),
                      Text(
                        context.s.pieceTitle(type),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The blunder guard's warning. Returns true to play the move anyway.
Future<bool> showRiskyMoveDialog(
  BuildContext context,
  PendingRiskyMove pending,
) async {
  final palette = context.palette;
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.shield_rounded, color: palette.accent, size: 40),
      title: Text(s.riskyTitle, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pending.review.allowsMate
                ? s.riskyMate
                : s.riskyLoss(pending.refutationSan),
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.5),
          ),
          if (pending.bestSan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.riskyBetter(pending.bestSan!),
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          children: [
            RoyalButton(
              label: s.riskyChooseAnother,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                s.riskyPlayAnyway,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A yes/no confirmation dialog.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? body,
  String? confirmLabel,
}) async {
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? s.yes),
        ),
      ],
    ),
  );
  return result ?? false;
}
