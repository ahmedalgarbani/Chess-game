/// Helpers for squares indexed 0..63, where a1 = 0, b1 = 1, ..., h8 = 63.
///
/// This is the indexing used by the public API. The board internally uses
/// the 0x88 layout; see [to0x88] and [from0x88].
abstract final class Square {
  static const String _files = 'abcdefgh';

  static int file(int square) => square & 7;

  static int rank(int square) => square >> 3;

  static int at(int file, int rank) => rank * 8 + file;

  static bool isValid(int square) => square >= 0 && square < 64;

  /// Whether the square is a light square (h1 is light, a1 is dark).
  static bool isLight(int square) => (file(square) + rank(square)).isOdd;

  /// Algebraic name, e.g. `e4`.
  static String name(int square) =>
      '${_files[file(square)]}${rank(square) + 1}';

  static String fileName(int square) => _files[file(square)];

  /// Parses an algebraic square name such as `e4`.
  static int parse(String name) {
    if (name.length != 2) {
      throw FormatException('Invalid square name', name);
    }
    final file = _files.indexOf(name[0]);
    final rank = int.tryParse(name[1]);
    if (file < 0 || rank == null || rank < 1 || rank > 8) {
      throw FormatException('Invalid square name', name);
    }
    return at(file, rank - 1);
  }

  /// Converts a 0..63 square to the internal 0x88 index.
  static int to0x88(int square) => square + (square & ~7);

  /// Converts an internal 0x88 index to a 0..63 square.
  static int from0x88(int index) => (index + (index & 7)) >> 1;

  /// Chebyshev distance (number of king moves) between two squares.
  static int distance(int a, int b) {
    final df = (file(a) - file(b)).abs();
    final dr = (rank(a) - rank(b)).abs();
    return df > dr ? df : dr;
  }
}
