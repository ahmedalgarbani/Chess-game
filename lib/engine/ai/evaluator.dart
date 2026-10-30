import 'dart:typed_data';

import '../src/board.dart';

/// Static position evaluation in centipawns from the side to move's point
/// of view.
///
/// Combines material, tapered piece-square tables (based on the
/// "Simplified Evaluation Function"), pawn structure, rook activity, king
/// shelter and a mop-up term that teaches the engine to finish won endgames.
abstract final class Evaluator {
  static const int _tempo = 10;

  static const List<int> _mgValue = [0, 100, 320, 330, 500, 900, 0];
  static const List<int> _egValue = [0, 120, 300, 320, 520, 940, 0];
  static const List<int> _phaseWeight = [0, 0, 1, 1, 2, 4, 0];

  // Tables are written from white's point of view with rank 8 on top.
  static const List<int> _pawnTable = [
    0, 0, 0, 0, 0, 0, 0, 0, //
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
    5, 5, 10, 25, 25, 10, 5, 5,
    0, 0, 0, 20, 20, 0, 0, 0,
    5, -5, -10, 0, 0, -10, -5, 5,
    5, 10, 10, -20, -20, 10, 10, 5,
    0, 0, 0, 0, 0, 0, 0, 0,
  ];

  static const List<int> _knightTable = [
    -50, -40, -30, -30, -30, -30, -40, -50, //
    -40, -20, 0, 0, 0, 0, -20, -40,
    -30, 0, 10, 15, 15, 10, 0, -30,
    -30, 5, 15, 20, 20, 15, 5, -30,
    -30, 0, 15, 20, 20, 15, 0, -30,
    -30, 5, 10, 15, 15, 10, 5, -30,
    -40, -20, 0, 5, 5, 0, -20, -40,
    -50, -40, -30, -30, -30, -30, -40, -50,
  ];

  static const List<int> _bishopTable = [
    -20, -10, -10, -10, -10, -10, -10, -20, //
    -10, 0, 0, 0, 0, 0, 0, -10,
    -10, 0, 5, 10, 10, 5, 0, -10,
    -10, 5, 5, 10, 10, 5, 5, -10,
    -10, 0, 10, 10, 10, 10, 0, -10,
    -10, 10, 10, 10, 10, 10, 10, -10,
    -10, 5, 0, 0, 0, 0, 5, -10,
    -20, -10, -10, -10, -10, -10, -10, -20,
  ];

  static const List<int> _rookTable = [
    0, 0, 0, 0, 0, 0, 0, 0, //
    5, 10, 10, 10, 10, 10, 10, 5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    -5, 0, 0, 0, 0, 0, 0, -5,
    0, 0, 0, 5, 5, 0, 0, 0,
  ];

  static const List<int> _queenTable = [
    -20, -10, -10, -5, -5, -10, -10, -20, //
    -10, 0, 0, 0, 0, 0, 0, -10,
    -10, 0, 5, 5, 5, 5, 0, -10,
    -5, 0, 5, 5, 5, 5, 0, -5,
    0, 0, 5, 5, 5, 5, 0, -5,
    -10, 5, 5, 5, 5, 5, 0, -10,
    -10, 0, 5, 0, 0, 0, 0, -10,
    -20, -10, -10, -5, -5, -10, -10, -20,
  ];

  static const List<int> _kingMiddleTable = [
    -30, -40, -40, -50, -50, -40, -40, -30, //
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -30, -40, -40, -50, -50, -40, -40, -30,
    -20, -30, -30, -40, -40, -30, -30, -20,
    -10, -20, -20, -20, -20, -20, -20, -10,
    20, 20, 0, 0, 0, 0, 20, 20,
    20, 30, 10, 0, 0, 10, 30, 20,
  ];

  static const List<int> _kingEndTable = [
    -50, -40, -30, -20, -20, -30, -40, -50, //
    -30, -20, -10, 0, 0, -10, -20, -30,
    -30, -10, 20, 30, 30, 20, -10, -30,
    -30, -10, 30, 40, 40, 30, -10, -30,
    -30, -10, 30, 40, 40, 30, -10, -30,
    -30, -10, 20, 30, 30, 20, -10, -30,
    -30, -30, 0, 0, 0, 0, -30, -30,
    -50, -30, -30, -30, -30, -30, -30, -50,
  ];

  static const List<int> _passedMg = [0, 5, 10, 15, 25, 40, 60, 0];
  static const List<int> _passedEg = [0, 10, 20, 35, 55, 85, 120, 0];

  /// Evaluates [board] from the perspective of the side to move.
  static int evaluate(Board board) {
    final squares = board.squares;
    var mg = 0;
    var eg = 0;
    var phase = 0;
    var whiteBishops = 0;
    var blackBishops = 0;
    var whiteMaterial = 0;
    var blackMaterial = 0;
    var whitePawnCount = 0;
    var blackPawnCount = 0;

    final whitePawnsOnFile = Int8List(8);
    final blackPawnsOnFile = Int8List(8);
    // Most advanced enemy-blocking information for passed pawn detection.
    final whiteLowestRank = Int8List(8)..fillRange(0, 8, 8);
    final blackHighestRank = Int8List(8)..fillRange(0, 8, -1);

    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final piece = squares[sq];
      if (piece == 0) continue;
      final type = piece > 0 ? piece : -piece;
      final file = sq & 7;
      final rank = sq >> 4;
      final white = piece > 0;
      final index = white ? (7 - rank) * 8 + file : rank * 8 + file;
      final sign = white ? 1 : -1;

      phase += _phaseWeight[type];
      var mgScore = _mgValue[type];
      var egScore = _egValue[type];
      switch (type) {
        case 1:
          mgScore += _pawnTable[index];
          egScore += _pawnTable[index] ~/ 2;
          if (white) {
            whitePawnsOnFile[file]++;
            whitePawnCount++;
            if (rank < whiteLowestRank[file]) whiteLowestRank[file] = rank;
          } else {
            blackPawnsOnFile[file]++;
            blackPawnCount++;
            if (rank > blackHighestRank[file]) blackHighestRank[file] = rank;
          }
        case 2:
          mgScore += _knightTable[index];
          egScore += _knightTable[index];
        case 3:
          mgScore += _bishopTable[index];
          egScore += _bishopTable[index];
          if (white) {
            whiteBishops++;
          } else {
            blackBishops++;
          }
        case 4:
          mgScore += _rookTable[index];
          egScore += _rookTable[index];
        case 5:
          mgScore += _queenTable[index];
          egScore += _queenTable[index];
        case 6:
          mgScore += _kingMiddleTable[index];
          egScore += _kingEndTable[index];
      }
      if (type != 6) {
        if (white) {
          whiteMaterial += _mgValue[type];
        } else {
          blackMaterial += _mgValue[type];
        }
      }
      mg += sign * mgScore;
      eg += sign * egScore;
    }

    // Pawn structure and rook files.
    for (var sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) {
        sq += 7;
        continue;
      }
      final piece = squares[sq];
      if (piece == 1 || piece == -1) {
        final file = sq & 7;
        final rank = sq >> 4;
        final white = piece > 0;
        final own = white ? whitePawnsOnFile : blackPawnsOnFile;
        final hasNeighbour =
            (file > 0 && own[file - 1] > 0) || (file < 7 && own[file + 1] > 0);
        final sign = white ? 1 : -1;
        if (!hasNeighbour) {
          mg -= sign * 10;
          eg -= sign * 15;
        }
        if (_isPassed(file, rank, white, whiteLowestRank, blackHighestRank)) {
          final relativeRank = white ? rank : 7 - rank;
          mg += sign * _passedMg[relativeRank];
          eg += sign * _passedEg[relativeRank];
        }
      } else if (piece == 4 || piece == -4) {
        final file = sq & 7;
        final white = piece > 0;
        final ownPawns = white
            ? whitePawnsOnFile[file]
            : blackPawnsOnFile[file];
        final enemyPawns = white
            ? blackPawnsOnFile[file]
            : whitePawnsOnFile[file];
        final sign = white ? 1 : -1;
        if (ownPawns == 0) mg += sign * (enemyPawns == 0 ? 20 : 10);
      }
    }
    for (var file = 0; file < 8; file++) {
      if (whitePawnsOnFile[file] > 1) {
        mg -= 12 * (whitePawnsOnFile[file] - 1);
        eg -= 20 * (whitePawnsOnFile[file] - 1);
      }
      if (blackPawnsOnFile[file] > 1) {
        mg += 12 * (blackPawnsOnFile[file] - 1);
        eg += 20 * (blackPawnsOnFile[file] - 1);
      }
    }

    if (whiteBishops >= 2) {
      mg += 30;
      eg += 45;
    }
    if (blackBishops >= 2) {
      mg -= 30;
      eg -= 45;
    }

    mg += _kingShelter(board, 1) - _kingShelter(board, -1);

    if (phase > 24) phase = 24;
    var score = (mg * phase + eg * (24 - phase)) ~/ 24;

    score += _mopUp(
      board,
      whiteMaterial,
      blackMaterial,
      whitePawnCount,
      blackPawnCount,
    );

    return board.turn == 1 ? score + _tempo : -score + _tempo;
  }

  static bool _isPassed(
    int file,
    int rank,
    bool white,
    Int8List whiteLowest,
    Int8List blackHighest,
  ) {
    final from = file > 0 ? file - 1 : 0;
    final to = file < 7 ? file + 1 : 7;
    for (var f = from; f <= to; f++) {
      if (white) {
        if (blackHighest[f] > rank) return false;
      } else {
        if (whiteLowest[f] < rank) return false;
      }
    }
    return true;
  }

  /// Bonus for pawns sheltering a king that stays on its back rank.
  static int _kingShelter(Board board, int side) {
    final king = side == 1 ? board.whiteKing : board.blackKing;
    if (king < 0) return 0;
    final homeRank = side == 1 ? 0 : 7;
    if ((king >> 4) != homeRank) return 0;
    final pawn = side;
    var bonus = 0;
    final file = king & 7;
    for (var f = file - 1; f <= file + 1; f++) {
      if (f < 0 || f > 7) continue;
      final first = (homeRank + side) * 16 + f;
      final second = (homeRank + 2 * side) * 16 + f;
      if (board.squares[first] == pawn) {
        bonus += 12;
      } else if (board.squares[second] == pawn) {
        bonus += 6;
      }
    }
    return bonus;
  }

  /// Rewards driving a lone enemy king to the edge and approaching it with
  /// the own king, so winning endgames are converted instead of shuffled.
  static int _mopUp(
    Board board,
    int whiteMaterial,
    int blackMaterial,
    int whitePawns,
    int blackPawns,
  ) {
    if (board.whiteKing < 0 || board.blackKing < 0) return 0;
    if (whiteMaterial - blackMaterial >= 300 &&
        blackPawns == 0 &&
        blackMaterial <= 330) {
      return _mopUpBonus(board.whiteKing, board.blackKing);
    }
    if (blackMaterial - whiteMaterial >= 300 &&
        whitePawns == 0 &&
        whiteMaterial <= 330) {
      return -_mopUpBonus(board.blackKing, board.whiteKing);
    }
    return 0;
  }

  static int _mopUpBonus(int winnerKing, int loserKing) {
    final lf = loserKing & 7;
    final lr = loserKing >> 4;
    final centerDistance =
        (lf < 4 ? 3 - lf : lf - 4) + (lr < 4 ? 3 - lr : lr - 4);
    final kingDistance =
        ((winnerKing & 7) - lf).abs() + ((winnerKing >> 4) - lr).abs();
    return 10 * centerDistance + 4 * (14 - kingDistance);
  }
}
