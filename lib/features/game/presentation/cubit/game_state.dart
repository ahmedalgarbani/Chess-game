import 'package:flutter/foundation.dart';

import '../../../../engine/chess_ai.dart';
import '../../../../engine/chess_engine.dart';
import '../../domain/coach/coach_note.dart';
import '../../domain/game_config.dart';
import '../../domain/game_outcome.dart';

/// The chess clock at one instant.
class ClockReading {
  const ClockReading({required this.white, required this.black, this.running});

  final Duration white;
  final Duration black;
  final PieceColor? running;

  Duration of(PieceColor color) => color == PieceColor.white ? white : black;
}

/// A suggested move with its explanation.
class Hint {
  const Hint(this.move, this.note);

  final Move move;
  final HintNote note;
}

/// A pawn waiting for the player to choose its promotion piece.
class PendingPromotion {
  const PendingPromotion({
    required this.from,
    required this.to,
    required this.color,
  });

  final int from;
  final int to;
  final PieceColor color;
}

/// A move the blunder guard asked the player to confirm.
class PendingRiskyMove {
  const PendingRiskyMove({
    required this.move,
    required this.review,
    this.refutationSan,
    this.bestSan,
  });

  final Move move;
  final MoveReview review;

  /// The opponent's punishing reply in SAN.
  final String? refutationSan;

  /// The engine's preferred move in SAN.
  final String? bestSan;
}

enum GameEventKind {
  drawDeclined,
  drawOffered,
  reaction,
  rematchDeclined,
  hintLimitReached,
  opponentLeft,
}

/// A one-off UI notification (snackbar, floating reaction, …). The
/// [serial] changes for every new event so listeners can react once.
class GameEvent {
  const GameEvent(this.kind, this.serial, {this.payload});

  final GameEventKind kind;
  final int serial;
  final String? payload;
}

/// Immutable snapshot of everything the game screen shows.
@immutable
class GameState {
  const GameState({
    required this.config,
    required this.pieces,
    required this.turn,
    this.moveCount = 0,
    this.history = const [],
    this.lastMove,
    this.checkSquare,
    this.whiteCaptured = const [],
    this.blackCaptured = const [],
    this.materialBalance = 0,
    this.selectedSquare,
    this.selectedMoves = const [],
    this.outcome,
    this.aiThinking = false,
    this.reviewingMove = false,
    this.hintLoading = false,
    this.coachNotes = const [],
    this.hint,
    this.analysis,
    this.predictedLine = const [],
    this.threatSan,
    this.dangerSquares = const [],
    this.pendingPromotion,
    this.pendingRisky,
    this.hintsUsed = 0,
    this.undosUsed = 0,
    this.flipped = false,
    this.canUndo = false,
    this.drawOfferedByOpponent = false,
    this.drawOfferPending = false,
    this.rematchOfferedByOpponent = false,
    this.rematchOfferPending = false,
    this.event,
  });

  final GameConfig config;

  /// The 64 squares, index 0 = a1.
  final List<Piece?> pieces;
  final PieceColor turn;
  final int moveCount;
  final List<MoveRecord> history;
  final Move? lastMove;
  final int? checkSquare;

  /// Black pieces captured by white, and vice versa.
  final List<Piece> whiteCaptured;
  final List<Piece> blackCaptured;

  /// Material difference in pawns from white's point of view.
  final int materialBalance;

  final int? selectedSquare;
  final List<Move> selectedMoves;
  final GameOutcome? outcome;

  final bool aiThinking;
  final bool reviewingMove;
  final bool hintLoading;

  /// Coach messages, newest first.
  final List<CoachNote> coachNotes;
  final Hint? hint;

  /// Engine analysis of the current position (for predictions).
  final PositionAnalysis? analysis;

  /// The expected continuation in SAN.
  final List<String> predictedLine;

  /// The opponent's threat in SAN (see [PositionAnalysis.threat]).
  final String? threatSan;

  /// Squares of the local player's pieces that are in danger.
  final List<int> dangerSquares;

  final PendingPromotion? pendingPromotion;
  final PendingRiskyMove? pendingRisky;
  final int hintsUsed;
  final int undosUsed;
  final bool flipped;
  final bool canUndo;

  final bool drawOfferedByOpponent;
  final bool drawOfferPending;
  final bool rematchOfferedByOpponent;
  final bool rematchOfferPending;
  final GameEvent? event;

  bool get isOver => outcome != null;

  /// Pieces captured by [color].
  List<Piece> capturedBy(PieceColor color) =>
      color == PieceColor.white ? whiteCaptured : blackCaptured;

  GameState copyWith({
    GameConfig? config,
    List<Piece?>? pieces,
    PieceColor? turn,
    int? moveCount,
    List<MoveRecord>? history,
    ValueGetter<Move?>? lastMove,
    ValueGetter<int?>? checkSquare,
    List<Piece>? whiteCaptured,
    List<Piece>? blackCaptured,
    int? materialBalance,
    ValueGetter<int?>? selectedSquare,
    List<Move>? selectedMoves,
    ValueGetter<GameOutcome?>? outcome,
    bool? aiThinking,
    bool? reviewingMove,
    bool? hintLoading,
    List<CoachNote>? coachNotes,
    ValueGetter<Hint?>? hint,
    ValueGetter<PositionAnalysis?>? analysis,
    List<String>? predictedLine,
    ValueGetter<String?>? threatSan,
    List<int>? dangerSquares,
    ValueGetter<PendingPromotion?>? pendingPromotion,
    ValueGetter<PendingRiskyMove?>? pendingRisky,
    int? hintsUsed,
    int? undosUsed,
    bool? flipped,
    bool? canUndo,
    bool? drawOfferedByOpponent,
    bool? drawOfferPending,
    bool? rematchOfferedByOpponent,
    bool? rematchOfferPending,
    ValueGetter<GameEvent?>? event,
  }) {
    return GameState(
      config: config ?? this.config,
      pieces: pieces ?? this.pieces,
      turn: turn ?? this.turn,
      moveCount: moveCount ?? this.moveCount,
      history: history ?? this.history,
      lastMove: lastMove != null ? lastMove() : this.lastMove,
      checkSquare: checkSquare != null ? checkSquare() : this.checkSquare,
      whiteCaptured: whiteCaptured ?? this.whiteCaptured,
      blackCaptured: blackCaptured ?? this.blackCaptured,
      materialBalance: materialBalance ?? this.materialBalance,
      selectedSquare: selectedSquare != null
          ? selectedSquare()
          : this.selectedSquare,
      selectedMoves: selectedMoves ?? this.selectedMoves,
      outcome: outcome != null ? outcome() : this.outcome,
      aiThinking: aiThinking ?? this.aiThinking,
      reviewingMove: reviewingMove ?? this.reviewingMove,
      hintLoading: hintLoading ?? this.hintLoading,
      coachNotes: coachNotes ?? this.coachNotes,
      hint: hint != null ? hint() : this.hint,
      analysis: analysis != null ? analysis() : this.analysis,
      predictedLine: predictedLine ?? this.predictedLine,
      threatSan: threatSan != null ? threatSan() : this.threatSan,
      dangerSquares: dangerSquares ?? this.dangerSquares,
      pendingPromotion: pendingPromotion != null
          ? pendingPromotion()
          : this.pendingPromotion,
      pendingRisky: pendingRisky != null ? pendingRisky() : this.pendingRisky,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      undosUsed: undosUsed ?? this.undosUsed,
      flipped: flipped ?? this.flipped,
      canUndo: canUndo ?? this.canUndo,
      drawOfferedByOpponent:
          drawOfferedByOpponent ?? this.drawOfferedByOpponent,
      drawOfferPending: drawOfferPending ?? this.drawOfferPending,
      rematchOfferedByOpponent:
          rematchOfferedByOpponent ?? this.rematchOfferedByOpponent,
      rematchOfferPending: rematchOfferPending ?? this.rematchOfferPending,
      event: event != null ? event() : this.event,
    );
  }
}
