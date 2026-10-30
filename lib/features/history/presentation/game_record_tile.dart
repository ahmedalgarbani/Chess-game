import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../engine/chess_engine.dart';
import '../../game/domain/game_config.dart';
import '../domain/game_record.dart';

/// One finished game: opponent, result and date.
class GameRecordTile extends StatelessWidget {
  const GameRecordTile({super.key, required this.record, this.onTap});

  final GameRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final won = record.playerWon;
    final winner = record.winner;
    final (IconData icon, Color color, String result) = switch (won) {
      true => (Icons.emoji_events_rounded, AppColors.emerald, s.resultWin),
      false => (Icons.flag_rounded, AppColors.ruby, s.resultLoss),
      null when winner == null => (
        Icons.handshake_rounded,
        AppColors.textSecondary,
        s.draw,
      ),
      null => (
        Icons.people_alt_rounded,
        AppColors.sapphire,
        s.wins(
          winner == PieceColor.white ? record.whiteName : record.blackName,
        ),
      ),
    };
    final title = record.mode == GameMode.local
        ? '${record.whiteName} – ${record.blackName}'
        : s.versus(record.opponentName);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 15,
                  ),
                ),
                Text(
                  '$result ${s.outcomeReason(record.reason)} · '
                  '${s.movesCount((record.moves.length + 1) ~/ 2)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                Text(
                  formatDateTime(record.playedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
