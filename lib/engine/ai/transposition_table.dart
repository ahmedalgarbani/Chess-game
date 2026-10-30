import 'dart:typed_data';

/// Bound type of a stored search score.
abstract final class TTBound {
  static const int exact = 0;
  static const int lower = 1;
  static const int upper = 2;
}

/// A fixed-size, always-replace transposition table stored in flat typed
/// arrays to avoid per-entry allocations during search.
class TranspositionTable {
  TranspositionTable({int sizeLog2 = 18})
    : _mask = (1 << sizeLog2) - 1,
      _keyLo = Uint32List(1 << sizeLog2),
      _keyHi = Uint32List(1 << sizeLog2),
      _move = Int32List(1 << sizeLog2),
      _score = Int32List(1 << sizeLog2),
      _depth = Int8List(1 << sizeLog2),
      _bound = Int8List(1 << sizeLog2),
      _used = Uint8List(1 << sizeLog2);

  final int _mask;
  final Uint32List _keyLo;
  final Uint32List _keyHi;
  final Int32List _move;
  final Int32List _score;
  final Int8List _depth;
  final Int8List _bound;
  final Uint8List _used;

  /// Returns the slot holding the position, or -1 when it is not stored.
  int probe(int hashLo, int hashHi) {
    final index = hashLo & _mask;
    if (_used[index] == 1 &&
        _keyLo[index] == hashLo &&
        _keyHi[index] == hashHi) {
      return index;
    }
    return -1;
  }

  int moveAt(int slot) => _move[slot];

  int scoreAt(int slot) => _score[slot];

  int depthAt(int slot) => _depth[slot];

  int boundAt(int slot) => _bound[slot];

  void store(
    int hashLo,
    int hashHi, {
    required int depth,
    required int score,
    required int bound,
    required int move,
  }) {
    final index = hashLo & _mask;
    // Prefer keeping deeper results for the same position.
    if (_used[index] == 1 &&
        _keyLo[index] == hashLo &&
        _keyHi[index] == hashHi &&
        _depth[index] > depth &&
        bound != TTBound.exact) {
      return;
    }
    _used[index] = 1;
    _keyLo[index] = hashLo;
    _keyHi[index] = hashHi;
    _depth[index] = depth > 127 ? 127 : depth;
    _score[index] = score;
    _bound[index] = bound;
    _move[index] = move;
  }

  void clear() => _used.fillRange(0, _used.length, 0);
}
