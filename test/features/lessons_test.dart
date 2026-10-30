import 'package:chess_game/engine/chess_engine.dart';
import 'package:chess_game/features/lessons/domain/lesson.dart';
import 'package:chess_game/features/lessons/domain/lesson_catalog.dart';
import 'package:chess_game/features/lessons/domain/lesson_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Depth-first search for a sequence of learner moves that solves the step.
bool solvable(LessonStep step, int depth) {
  bool search(List<String> played) {
    final session = LessonSession(step);
    for (final uci in played) {
      final move = _find(session, uci);
      if (move == null || session.play(move) == LessonMoveResult.wrong) {
        return false;
      }
    }
    if (session.isSolved) return true;
    if (played.length >= depth) return false;
    for (var square = 0; square < 64; square++) {
      for (final move in session.legalMovesFrom(square)) {
        if (search([...played, move.uci])) return true;
      }
    }
    return false;
  }

  return search(const []);
}

Move? _find(LessonSession session, String uci) {
  final from = Square.parse(uci.substring(0, 2));
  for (final move in session.legalMovesFrom(from)) {
    if (move.uci == uci) return move;
  }
  return null;
}

void main() {
  test('lesson ids are unique', () {
    final ids = LessonCatalog.lessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final lesson in LessonCatalog.lessons) {
    for (final (index, step) in lesson.steps.indexed) {
      test('${lesson.id} step ${index + 1} is valid and solvable', () {
        // The position must load.
        final session = LessonSession(step);
        for (final name in step.highlights) {
          expect(() => Square.parse(name), returnsNormally);
        }
        if (step.goal == null) {
          expect(session.isSolved, isTrue);
          return;
        }
        final depth = switch (step.goal!) {
          CollectStarsGoal(:final stars) => stars.length * 2,
          CaptureAllGoal() => 3,
          _ => 1,
        };
        expect(solvable(step, depth), isTrue);
      });
    }
  }

  test('wrong moves are taken back', () {
    final step = LessonCatalog.byId('checkmate')!.steps.first;
    final session = LessonSession(step);
    final before = session.pieces;
    final notMate = _find(session, 'a1a7')!;
    expect(session.play(notMate), LessonMoveResult.wrong);
    expect(session.pieces, before);
    expect(session.play(_find(session, 'a1a8')!), LessonMoveResult.solved);
  });
}
