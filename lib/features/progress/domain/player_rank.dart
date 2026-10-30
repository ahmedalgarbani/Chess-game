/// Titles unlocked as the player levels up.
enum RankTitle { novice, amateur, clubPlayer, pro, expert, master, grandmaster }

/// Experience curve: level n starts at 50·n·(n−1) XP.
abstract final class PlayerRank {
  static int xpForLevel(int level) => 50 * level * (level - 1);

  static int levelForXp(int xp) {
    var level = 1;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  /// Progress through the current level, from 0 to 1.
  static double progressInLevel(int xp) {
    final level = levelForXp(xp);
    final start = xpForLevel(level);
    final end = xpForLevel(level + 1);
    return (xp - start) / (end - start);
  }

  static RankTitle titleFor(int level) => switch (level) {
    <= 2 => RankTitle.novice,
    <= 4 => RankTitle.amateur,
    <= 7 => RankTitle.clubPlayer,
    <= 10 => RankTitle.pro,
    <= 14 => RankTitle.expert,
    <= 19 => RankTitle.master,
    _ => RankTitle.grandmaster,
  };
}
