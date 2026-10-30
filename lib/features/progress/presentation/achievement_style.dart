import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/achievement.dart';

extension AchievementStyle on Achievement {
  IconData get icon => switch (this) {
    Achievement.firstGame => Icons.flag_rounded,
    Achievement.firstWin => Icons.emoji_events_rounded,
    Achievement.castling => Icons.castle_rounded,
    Achievement.promotion => Icons.upgrade_rounded,
    Achievement.enPassant => Icons.compare_arrows_rounded,
    Achievement.pureWin => Icons.verified_rounded,
    Achievement.quickWin => Icons.bolt_rounded,
    Achievement.checkmates5 => Icons.workspace_premium_rounded,
    Achievement.beatLevel5 => Icons.shield_rounded,
    Achievement.beatLevel10 => Icons.military_tech_rounded,
    Achievement.allLessons => Icons.school_rounded,
    Achievement.friendlyGame => Icons.people_alt_rounded,
    Achievement.lanGame => Icons.wifi_rounded,
    Achievement.dailyStreak3 => Icons.local_fire_department_rounded,
    Achievement.tenWins => Icons.stars_rounded,
    Achievement.firstPurchase => Icons.shopping_bag_rounded,
    Achievement.collector => Icons.collections_bookmark_rounded,
    Achievement.puzzles10 => Icons.extension_rounded,
    Achievement.allPuzzles => Icons.psychology_rounded,
    Achievement.dailyPuzzle => Icons.today_rounded,
  };

  Color get color => switch (this) {
    Achievement.beatLevel10 ||
    Achievement.checkmates5 ||
    Achievement.tenWins => AppColors.amber,
    Achievement.pureWin || Achievement.quickWin => AppColors.ruby,
    Achievement.allLessons ||
    Achievement.enPassant ||
    Achievement.puzzles10 ||
    Achievement.allPuzzles => AppColors.amethyst,
    Achievement.firstPurchase || Achievement.collector => AppColors.amber,
    Achievement.lanGame || Achievement.friendlyGame => AppColors.sapphire,
    _ => AppColors.emerald,
  };
}
