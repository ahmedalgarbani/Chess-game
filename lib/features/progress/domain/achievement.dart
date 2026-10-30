/// Badges the player can earn. Each one pays out [coins] once.
enum Achievement {
  firstGame(10),
  firstWin(20),
  castling(10),
  promotion(15),
  enPassant(25),
  pureWin(30),
  quickWin(30),
  checkmates5(40),
  beatLevel5(50),
  beatLevel10(150),
  allLessons(50),
  friendlyGame(10),
  lanGame(20),
  dailyStreak3(30),
  tenWins(50);

  const Achievement(this.coins);

  final int coins;

  static Achievement? byName(String name) =>
      values.where((a) => a.name == name).firstOrNull;
}
