import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/chess_engine.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_session.dart';

enum PuzzleFeedback { none, correct, wrong, solved }

class PuzzleState {
  const PuzzleState({
    required this.puzzle,
    required this.pieces,
    required this.solverColor,
    this.selectedSquare,
    this.selectedMoves = const [],
    this.lastMove,
    this.moveCount = 0,
    this.feedback = PuzzleFeedback.none,
    this.feedbackSerial = 0,
    this.hintSquare,
    this.opponentToMove = false,
    this.promotionSquares,
  });

  final Puzzle puzzle;
  final List<Piece?> pieces;
  final PieceColor solverColor;
  final int? selectedSquare;
  final List<Move> selectedMoves;
  final Move? lastMove;
  final int moveCount;
  final PuzzleFeedback feedback;
  final int feedbackSerial;

  /// The piece to move, once the solver asked for a hint.
  final int? hintSquare;

  /// The opponent is about to answer the solver's move.
  final bool opponentToMove;

  /// A promotion waiting for the piece choice (from, to).
  final (int, int)? promotionSquares;

  bool get solved => feedback == PuzzleFeedback.solved;

  bool get canMove => !solved && !opponentToMove && promotionSquares == null;
}

/// Drives one puzzle attempt: the solver's moves, the opponent's replies
/// and hints.
class PuzzleCubit extends Cubit<PuzzleState> {
  PuzzleCubit(
    Puzzle puzzle, {
    Duration replyDelay = const Duration(milliseconds: 550),
  }) : this._(PuzzleSession(puzzle), replyDelay);

  PuzzleCubit._(PuzzleSession session, this.replyDelay)
    : _session = session,
      super(_initialState(session));

  /// Pause before the opponent answers, so both moves can be followed.
  final Duration replyDelay;

  PuzzleSession _session;
  int _serial = 0;
  int _generation = 0;

  static PuzzleState _initialState(PuzzleSession session) => PuzzleState(
    puzzle: session.puzzle,
    pieces: session.pieces,
    solverColor: session.solverColor,
  );

  void tapSquare(int square) {
    if (!state.canMove) return;
    final selected = state.selectedSquare;
    if (selected != null && state.selectedMoves.any((m) => m.to == square)) {
      _move(selected, square);
      return;
    }
    _select(selected == square ? null : square);
  }

  void startDrag(int square) {
    if (state.canMove && state.selectedSquare != square) _select(square);
  }

  void dropPiece(int from, int to) {
    if (!state.canMove) return;
    if (_session.legalMovesFrom(from).any((m) => m.to == to)) {
      _move(from, to);
    } else {
      _select(null);
    }
  }

  void choosePromotion(PieceType? type) {
    final squares = state.promotionSquares;
    emit(_copy(promotionSquares: null));
    if (squares == null || type == null) return;
    final move = _session
        .legalMovesFrom(squares.$1)
        .where((m) => m.to == squares.$2 && m.promotion == type)
        .firstOrNull;
    if (move != null) _play(move);
  }

  /// Highlights the piece that has to move.
  void showHint() {
    if (!state.canMove) return;
    emit(
      _copy(
        hintSquare: _session.hintSquare,
        feedback: state.feedback == PuzzleFeedback.wrong
            ? PuzzleFeedback.none
            : null,
      ),
    );
  }

  void restart() {
    _generation++;
    _session = PuzzleSession(state.puzzle);
    emit(_initialState(_session));
  }

  void _select(int? square) {
    final moves = square == null
        ? const <Move>[]
        : _session.legalMovesFrom(square);
    emit(
      _copy(
        selectedSquare: moves.isEmpty ? null : square,
        selectedMoves: moves,
      ),
    );
  }

  void _move(int from, int to) {
    final candidates = [
      for (final m in _session.legalMovesFrom(from))
        if (m.to == to) m,
    ];
    if (candidates.isEmpty) return;
    if (candidates.first.isPromotion) {
      emit(_copy(promotionSquares: (from, to)));
      return;
    }
    _play(candidates.first);
  }

  void _play(Move move) {
    final result = _session.play(move);
    final wrong = result == PuzzleMoveResult.wrong;
    emit(
      _copy(
        pieces: _session.pieces,
        lastMove: wrong ? state.lastMove : move,
        moveCount: wrong ? state.moveCount : state.moveCount + 1,
        feedback: switch (result) {
          PuzzleMoveResult.correct => PuzzleFeedback.correct,
          PuzzleMoveResult.solved => PuzzleFeedback.solved,
          PuzzleMoveResult.wrong => PuzzleFeedback.wrong,
        },
        feedbackSerial: ++_serial,
        selectedSquare: null,
        selectedMoves: const [],
        hintSquare: wrong ? state.hintSquare : null,
        opponentToMove: result == PuzzleMoveResult.correct,
      ),
    );
    if (result == PuzzleMoveResult.correct) unawaited(_reply());
  }

  Future<void> _reply() async {
    final generation = _generation;
    await Future<void>.delayed(replyDelay);
    if (isClosed || generation != _generation) return;
    final reply = _session.playReply();
    emit(
      _copy(
        pieces: _session.pieces,
        lastMove: reply ?? state.lastMove,
        moveCount: state.moveCount + 1,
        opponentToMove: false,
      ),
    );
  }

  PuzzleState _copy({
    List<Piece?>? pieces,
    Object? selectedSquare = _keep,
    List<Move>? selectedMoves,
    Move? lastMove,
    int? moveCount,
    PuzzleFeedback? feedback,
    int? feedbackSerial,
    Object? hintSquare = _keep,
    bool? opponentToMove,
    Object? promotionSquares = _keep,
  }) {
    return PuzzleState(
      puzzle: state.puzzle,
      pieces: pieces ?? state.pieces,
      solverColor: state.solverColor,
      selectedSquare: identical(selectedSquare, _keep)
          ? state.selectedSquare
          : selectedSquare as int?,
      selectedMoves: selectedMoves ?? state.selectedMoves,
      lastMove: lastMove ?? state.lastMove,
      moveCount: moveCount ?? state.moveCount,
      feedback: feedback ?? state.feedback,
      feedbackSerial: feedbackSerial ?? state.feedbackSerial,
      hintSquare: identical(hintSquare, _keep)
          ? state.hintSquare
          : hintSquare as int?,
      opponentToMove: opponentToMove ?? state.opponentToMove,
      promotionSquares: identical(promotionSquares, _keep)
          ? state.promotionSquares
          : promotionSquares as (int, int)?,
    );
  }

  static const Object _keep = Object();
}
