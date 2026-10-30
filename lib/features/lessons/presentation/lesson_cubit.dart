import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/chess_engine.dart';
import '../domain/lesson.dart';
import '../domain/lesson_session.dart';

enum LessonFeedback { none, success, wrong }

class LessonState {
  const LessonState({
    required this.lesson,
    required this.stepIndex,
    required this.pieces,
    required this.learnerColor,
    this.selectedSquare,
    this.selectedMoves = const [],
    this.lastMove,
    this.moveCount = 0,
    this.stars = const {},
    this.feedback = LessonFeedback.none,
    this.feedbackSerial = 0,
    this.stepSolved = false,
    this.completed = false,
    this.promotionSquares,
  });

  final Lesson lesson;
  final int stepIndex;
  final List<Piece?> pieces;
  final PieceColor learnerColor;
  final int? selectedSquare;
  final List<Move> selectedMoves;
  final Move? lastMove;
  final int moveCount;
  final Set<int> stars;
  final LessonFeedback feedback;
  final int feedbackSerial;
  final bool stepSolved;
  final bool completed;

  /// A promotion waiting for the piece choice (from, to).
  final (int, int)? promotionSquares;

  LessonStep get step => lesson.steps[stepIndex];

  bool get isLastStep => stepIndex == lesson.steps.length - 1;
}

/// Drives an interactive lesson step by step.
class LessonCubit extends Cubit<LessonState> {
  LessonCubit(Lesson lesson)
    : this._(LessonSession(lesson.steps.first), lesson);

  LessonCubit._(LessonSession session, Lesson lesson)
    : _session = session,
      super(_stateFor(lesson, 0, session));

  LessonSession _session;
  int _serial = 0;

  static LessonState _stateFor(
    Lesson lesson,
    int index,
    LessonSession session,
  ) {
    return LessonState(
      lesson: lesson,
      stepIndex: index,
      pieces: session.pieces,
      learnerColor: session.learnerColor,
      stars: session.remainingStars,
      stepSolved: session.isSolved,
    );
  }

  void tapSquare(int square) {
    if (state.stepSolved) return;
    final selected = state.selectedSquare;
    if (selected != null && state.selectedMoves.any((m) => m.to == square)) {
      _move(selected, square);
      return;
    }
    _select(selected == square ? null : square);
  }

  void startDrag(int square) {
    if (!state.stepSolved && state.selectedSquare != square) _select(square);
  }

  void dropPiece(int from, int to) {
    if (state.stepSolved) return;
    if (_session.legalMovesFrom(from).any((m) => m.to == to)) {
      _move(from, to);
    } else {
      _select(null);
    }
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

  void _play(Move move) {
    final result = _session.play(move);
    final solved = result == LessonMoveResult.solved;
    emit(
      _copy(
        pieces: _session.pieces,
        lastMove: result == LessonMoveResult.wrong ? state.lastMove : move,
        moveCount: result == LessonMoveResult.wrong
            ? state.moveCount
            : state.moveCount + 1,
        stars: _session.remainingStars,
        stepSolved: solved,
        feedback: switch (result) {
          LessonMoveResult.solved => LessonFeedback.success,
          LessonMoveResult.wrong => LessonFeedback.wrong,
          LessonMoveResult.progress => LessonFeedback.none,
        },
        feedbackSerial: ++_serial,
        selectedSquare: null,
        selectedMoves: const [],
      ),
    );
  }

  void nextStep() {
    if (!state.stepSolved) return;
    if (state.isLastStep) {
      emit(_copy(completed: true));
      return;
    }
    _loadStep(state.stepIndex + 1);
  }

  void restartStep() => _loadStep(state.stepIndex);

  void _loadStep(int index) {
    _session = LessonSession(state.lesson.steps[index]);
    emit(_stateFor(state.lesson, index, _session));
  }

  LessonState _copy({
    List<Piece?>? pieces,
    Object? selectedSquare = _keep,
    List<Move>? selectedMoves,
    Move? lastMove,
    int? moveCount,
    Set<int>? stars,
    LessonFeedback? feedback,
    int? feedbackSerial,
    bool? stepSolved,
    bool? completed,
    Object? promotionSquares = _keep,
  }) {
    return LessonState(
      lesson: state.lesson,
      stepIndex: state.stepIndex,
      pieces: pieces ?? state.pieces,
      learnerColor: state.learnerColor,
      selectedSquare: identical(selectedSquare, _keep)
          ? state.selectedSquare
          : selectedSquare as int?,
      selectedMoves: selectedMoves ?? state.selectedMoves,
      lastMove: lastMove ?? state.lastMove,
      moveCount: moveCount ?? state.moveCount,
      stars: stars ?? state.stars,
      feedback: feedback ?? state.feedback,
      feedbackSerial: feedbackSerial ?? state.feedbackSerial,
      stepSolved: stepSolved ?? state.stepSolved,
      completed: completed ?? state.completed,
      promotionSquares: identical(promotionSquares, _keep)
          ? state.promotionSquares
          : promotionSquares as (int, int)?,
    );
  }

  static const Object _keep = Object();
}
