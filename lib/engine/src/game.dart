import 'dart:typed_data';

import 'board.dart';
import 'move.dart';
import 'piece.dart';
import 'square.dart';

/// Why a game is (or is not) over, as determined by the rules alone.
enum GameStatus {
  ongoing,
  checkmate,
  stalemate,
  insufficientMaterial,
  fiftyMoveRule,
  threefoldRepetition;

  bool get isDraw =>
      this == stalemate ||
      this == insufficientMaterial ||
      this == fiftyMoveRule ||
      this == threefoldRepetition;
}

/// A move that has been played, together with its notation.
class MoveRecord {
  const MoveRecord({
    required this.move,
    required this.san,
    required this.moveNumber,
    required this.fenBefore,
  });

  final Move move;

  /// Standard algebraic notation, e.g. `Nf3`, `exd5`, `O-O`, `Qh7#`.
  final String san;

  /// The full-move number the move belongs to.
  final int moveNumber;

  /// Position before the move was played.
  final String fenBefore;

  PieceColor get color => move.piece.color;
}

/// A complete chess game: the rules engine plus history, notation and
/// result detection. This is the API used by the app.
class ChessGame {
  ChessGame({String fen = startingFen})
    : startFen = fen,
      _board = Board.fromFen(fen) {
    _repetitions[_board.positionKey()] = 1;
    _refreshStatus();
  }

  /// Rebuilds a game by replaying [uciMoves] from [startFen].
  ///
  /// Throws an [ArgumentError] if one of the moves is illegal.
  factory ChessGame.fromMoves(
    List<String> uciMoves, {
    String startFen = startingFen,
  }) {
    final game = ChessGame(fen: startFen);
    for (final uci in uciMoves) {
      if (game.playUci(uci) == null) {
        throw ArgumentError.value(uci, 'uciMoves', 'Illegal move');
      }
    }
    return game;
  }

  final String startFen;
  final Board _board;
  final List<MoveRecord> _history = [];
  final Map<String, int> _repetitions = {};
  List<Move>? _legalMoves;
  GameStatus _status = GameStatus.ongoing;

  /// Read-only access to the underlying board for analysis helpers.
  Board get board => _board;

  PieceColor get turn => PieceColor.fromSign(_board.turn);

  GameStatus get status => _status;

  bool get isGameOver => _status != GameStatus.ongoing;

  bool get isCheck => _board.inCheck;

  bool get isCheckmate => _status == GameStatus.checkmate;

  /// The winner when the game ended in checkmate, otherwise null.
  PieceColor? get winner =>
      _status == GameStatus.checkmate ? turn.opposite : null;

  String get fen => _board.toFen();

  int get halfmoveClock => _board.halfmoveClock;

  int get fullmoveNumber => _board.fullmoveNumber;

  List<MoveRecord> get history => List.unmodifiable(_history);

  List<String> get uciMoves => [for (final r in _history) r.move.uci];

  Move? get lastMove => _history.isEmpty ? null : _history.last.move;

  Piece? pieceAt(int square) => _board.pieceAt(square);

  /// All 64 squares, index 0 = a1.
  List<Piece?> get pieces => List.generate(64, pieceAt, growable: false);

  /// The square of the king of [color], or null if absent.
  int? kingSquare(PieceColor color) {
    final sq = color == PieceColor.white ? _board.whiteKing : _board.blackKing;
    return sq < 0 ? null : Square.from0x88(sq);
  }

  List<Move> get legalMoves {
    return _legalMoves ??= List.unmodifiable([
      for (final encoded in _board.legalMoves()) _board.decode(encoded),
    ]);
  }

  List<Move> legalMovesFrom(int square) => [
    for (final m in legalMoves)
      if (m.from == square) m,
  ];

  /// Finds the legal move from [from] to [to]. For promotions, [promotion]
  /// selects the piece (defaults to a queen).
  Move? findMove(int from, int to, {PieceType? promotion}) {
    Move? fallback;
    for (final m in legalMoves) {
      if (m.from != from || m.to != to) continue;
      if (m.promotion == null || m.promotion == promotion) return m;
      if (m.promotion == PieceType.queen) fallback = m;
    }
    return fallback;
  }

  Move? moveFromUci(String uci) {
    for (final m in legalMoves) {
      if (m.uci == uci) return m;
    }
    return null;
  }

  /// Plays a legal [move] and returns its record.
  ///
  /// Throws an [ArgumentError] if the move is not legal in this position.
  MoveRecord play(Move move) {
    final legal = legalMoves;
    if (!legal.contains(move)) {
      throw ArgumentError.value(move.uci, 'move', 'Illegal move');
    }
    final encoded = _encode(move);
    final fenBefore = _board.toFen();
    final moveNumber = _board.fullmoveNumber;
    final sanBase = _sanWithoutSuffix(move, legal);

    _board.makeMove(encoded);
    _legalMoves = null;
    final key = _board.positionKey();
    _repetitions[key] = (_repetitions[key] ?? 0) + 1;
    _refreshStatus();

    final suffix = _status == GameStatus.checkmate
        ? '#'
        : _board.inCheck
        ? '+'
        : '';
    final record = MoveRecord(
      move: move,
      san: '$sanBase$suffix',
      moveNumber: moveNumber,
      fenBefore: fenBefore,
    );
    _history.add(record);
    return record;
  }

  /// Plays a move given in UCI notation. Returns null if it is illegal.
  MoveRecord? playUci(String uci) {
    final move = moveFromUci(uci);
    return move == null ? null : play(move);
  }

  /// The SAN of a legal [move], without playing it.
  String sanOf(Move move) {
    final san = play(move).san;
    undo();
    return san;
  }

  /// Converts a line of UCI moves starting from the current position into
  /// SAN, stopping at the first illegal move. The game is left unchanged.
  List<String> sanLine(List<String> uciMoves) {
    final sans = <String>[];
    for (final uci in uciMoves) {
      final record = playUci(uci);
      if (record == null) break;
      sans.add(record.san);
    }
    for (var i = 0; i < sans.length; i++) {
      undo();
    }
    return sans;
  }

  bool get canUndo => _history.isNotEmpty;

  /// Takes back the last move.
  void undo() {
    if (_history.isEmpty) return;
    final key = _board.positionKey();
    final count = (_repetitions[key] ?? 1) - 1;
    if (count <= 0) {
      _repetitions.remove(key);
    } else {
      _repetitions[key] = count;
    }
    _board.unmakeMove();
    _history.removeLast();
    _legalMoves = null;
    _refreshStatus();
  }

  /// Pieces of [color] that have been captured so far.
  List<Piece> capturedPieces(PieceColor color) => [
    for (final r in _history)
      if (r.move.captured?.color == color) r.move.captured!,
  ];

  /// Material balance in pawns from white's point of view.
  int get materialBalance {
    var balance = 0;
    for (var sq = 0; sq < 64; sq++) {
      final piece = pieceAt(sq);
      if (piece == null) continue;
      balance += piece.type.value * piece.color.sign;
    }
    return balance;
  }

  /// Whether [color] still has enough material to possibly checkmate.
  bool hasMatingMaterial(PieceColor color) =>
      _board.hasMatingMaterial(color.sign);

  ChessGame copy() => ChessGame.fromMoves(uciMoves, startFen: startFen);

  void _refreshStatus() {
    if (legalMoves.isEmpty) {
      _status = _board.inCheck ? GameStatus.checkmate : GameStatus.stalemate;
    } else if (_board.hasInsufficientMaterial) {
      _status = GameStatus.insufficientMaterial;
    } else if (_board.halfmoveClock >= 100) {
      _status = GameStatus.fiftyMoveRule;
    } else if ((_repetitions[_board.positionKey()] ?? 0) >= 3) {
      _status = GameStatus.threefoldRepetition;
    } else {
      _status = GameStatus.ongoing;
    }
  }

  int _encode(Move move) {
    final buffer = Int32List(256);
    final count = _board.generateLegalMoves(buffer, 0);
    final from = Square.to0x88(move.from);
    final to = Square.to0x88(move.to);
    final promotion = move.promotion?.code ?? 0;
    for (var i = 0; i < count; i++) {
      final m = buffer[i];
      if (MoveBits.from(m) == from &&
          MoveBits.to(m) == to &&
          MoveBits.promotion(m) == promotion) {
        return m;
      }
    }
    throw ArgumentError.value(move.uci, 'move', 'Illegal move');
  }

  static String _sanWithoutSuffix(Move move, List<Move> legal) {
    if (move.kind == MoveKind.castleKingside) return 'O-O';
    if (move.kind == MoveKind.castleQueenside) return 'O-O-O';

    final buffer = StringBuffer();
    final target = Square.name(move.to);
    if (move.piece.type == PieceType.pawn) {
      if (move.isCapture) {
        buffer
          ..write(Square.fileName(move.from))
          ..write('x');
      }
      buffer.write(target);
      if (move.promotion != null) {
        buffer.write('=${move.promotion!.sanLetter}');
      }
      return buffer.toString();
    }

    buffer.write(move.piece.type.sanLetter);
    final rivals = legal.where(
      (m) => m.piece == move.piece && m.to == move.to && m.from != move.from,
    );
    if (rivals.isNotEmpty) {
      final sameFile = rivals.any(
        (m) => Square.file(m.from) == Square.file(move.from),
      );
      final sameRank = rivals.any(
        (m) => Square.rank(m.from) == Square.rank(move.from),
      );
      if (!sameFile) {
        buffer.write(Square.fileName(move.from));
      } else if (!sameRank) {
        buffer.write(Square.rank(move.from) + 1);
      } else {
        buffer.write(Square.name(move.from));
      }
    }
    if (move.isCapture) buffer.write('x');
    buffer.write(target);
    return buffer.toString();
  }
}
