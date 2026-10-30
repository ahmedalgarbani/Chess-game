/// Hints bought with coins, spent once a game's free hints are used up.
abstract interface class HintWallet {
  int get balance;

  /// Spends one hint; returns false when none is left.
  bool spend();
}
