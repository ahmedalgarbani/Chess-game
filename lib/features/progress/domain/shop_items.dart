/// Kinds of cosmetic items sold in the shop, with the ones every player
/// owns from the start.
enum CosmeticKind {
  appTheme({'royal'}),
  board({'royal', 'midnight'}),
  pieces({'royal', 'classic'}),
  frame({'classic'}),

  /// The empty id stands for the automatic rank title.
  title({''});

  const CosmeticKind(this.starterItems);

  final Set<String> starterItems;

  static CosmeticKind? byName(String name) =>
      values.where((k) => k.name == name).firstOrNull;
}

/// Consumable power-ups bought with coins.
enum Boost {
  /// Extra hints, used once a game's free hints are spent.
  hintPack(price: 80, amount: 5),

  /// Double experience for the next few finished games.
  xpBooster(price: 150, amount: 3),

  /// Keeps the daily streak alive after one missed day.
  streakShield(price: 100, amount: 1);

  const Boost({required this.price, required this.amount});

  final int price;

  /// How many hints, games or shields one purchase gives.
  final int amount;
}

/// Player titles for sale (ids are localised by the presentation layer).
abstract final class TitleCatalog {
  static const prices = <String, int>{
    'knightOfBoard': 150,
    'kingHunter': 250,
    'tactician': 300,
    'strategist': 350,
    'desertFalcon': 400,
    'sultan': 800,
    'legend': 1500,
  };
}
