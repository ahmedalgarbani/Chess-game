import 'package:chess_game/engine/chess_ai.dart';
import 'package:chess_game/engine/chess_engine.dart';
import 'package:chess_game/features/puzzles/domain/mate_search.dart';
import 'package:chess_game/features/puzzles/domain/puzzle_catalog.dart';
import 'package:chess_game/features/puzzles/domain/puzzle_session.dart';
import 'package:chess_game/features/puzzles/presentation/puzzle_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Move legal(PuzzleSession session, String uci) => session
    .legalMovesFrom(Square.parse(uci.substring(0, 2)))
    .firstWhere((m) => m.uci == uci);

void main() {
  test('puzzle ids are unique', () {
    final ids = PuzzleCatalog.puzzles.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final puzzle in PuzzleCatalog.puzzles) {
    group(puzzle.id, () {
      test('the solution is legal and accepted', () {
        expect(puzzle.solution.length.isOdd, isTrue);
        final session = PuzzleSession(puzzle);
        for (var i = 0; i < puzzle.solution.length; i += 2) {
          final result = session.play(legal(session, puzzle.solution[i]));
          if (i + 1 < puzzle.solution.length) {
            expect(result, PuzzleMoveResult.correct);
            expect(session.playReply()?.uci, puzzle.solution[i + 1]);
          } else {
            expect(result, PuzzleMoveResult.solved);
          }
        }
        expect(session.isSolved, isTrue);
      });

      if (puzzle.theme.isMate) {
        test('ends in mate and has no shorter mate', () {
          final board = Board.fromFen(puzzle.fen);
          for (final uci in puzzle.solution) {
            board.makeMove(board.findMove(uci)!);
          }
          expect(MateSearch.isMate(board), isTrue);
          if (puzzle.solverMoves > 1) {
            final start = Board.fromFen(puzzle.fen);
            expect(MateSearch.canMate(start, puzzle.solverMoves), isTrue);
            expect(MateSearch.canMate(start, puzzle.solverMoves - 1), isFalse);
          }
        });
      } else {
        test('the engine agrees with every solver move', () {
          final board = Board.fromFen(puzzle.fen);
          for (var i = 0; i < puzzle.solution.length; i++) {
            if (i.isEven) {
              final analysis = ChessAi.analyze(
                board,
                maxDepth: 5,
                timeLimitMs: 2000,
                includeThreat: false,
              );
              expect(analysis.bestMove, puzzle.solution[i]);
            }
            board.makeMove(board.findMove(puzzle.solution[i])!);
          }
        });
      }
    });
  }

  test('a wrong move is taken back', () {
    final puzzle = PuzzleCatalog.byId('knight-fork-rook')!;
    final session = PuzzleSession(puzzle);
    final before = session.pieces;
    final result = session.play(legal(session, 'b5d6'));
    expect(result, PuzzleMoveResult.wrong);
    expect(session.pieces, before);
    expect(session.hintSquare, Square.parse('b5'));
  });

  test('any checkmate solves the puzzle', () {
    final session = PuzzleSession(PuzzleCatalog.byId('queen-corner')!);
    final result = session.play(legal(session, 'h1b7'));
    expect(result, PuzzleMoveResult.solved);
  });

  test('another forced mate is accepted in a mate in two', () {
    final puzzle = PuzzleCatalog.byId('rook-roller')!;
    final board = Board.fromFen(puzzle.fen);
    final alternative = board.legalMoves().firstWhere((move) {
      if (board.decode(move).uci == puzzle.solution.first) return false;
      board.makeMove(move);
      final forced = MateSearch.everyReplyLoses(board, 1);
      board.unmakeMove();
      return forced;
    });
    final session = PuzzleSession(puzzle);
    final first = session.play(legal(session, board.decode(alternative).uci));
    expect(first, PuzzleMoveResult.correct);
    final reply = session.playReply();

    board
      ..makeMove(alternative)
      ..makeMove(board.findMove(reply!.uci)!);
    final mate = board.legalMoves().firstWhere((move) {
      board.makeMove(move);
      final mates = MateSearch.isMate(board);
      board.unmakeMove();
      return mates;
    });
    final second = session.play(legal(session, board.decode(mate).uci));
    expect(second, PuzzleMoveResult.solved);
  });

  test('the daily puzzle changes with the day', () {
    final today = DateTime(2026, 10, 30, 8);
    expect(
      PuzzleCatalog.daily(today).id,
      PuzzleCatalog.daily(DateTime(2026, 10, 30, 23)).id,
    );
    expect(
      PuzzleCatalog.daily(today).id,
      isNot(PuzzleCatalog.daily(today.add(const Duration(days: 1))).id),
    );
  });

  test('the cubit plays the reply, shows hints and restarts', () async {
    final cubit = PuzzleCubit(
      PuzzleCatalog.byId('knight-fork-rook')!,
      replyDelay: Duration.zero,
    );
    cubit.showHint();
    expect(cubit.state.hintSquare, Square.parse('b5'));

    cubit.dropPiece(Square.parse('b5'), Square.parse('d6'));
    expect(cubit.state.feedback, PuzzleFeedback.wrong);
    expect(cubit.state.moveCount, 0);

    cubit.dropPiece(Square.parse('b5'), Square.parse('c7'));
    expect(cubit.state.feedback, PuzzleFeedback.correct);
    expect(cubit.state.canMove, isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.lastMove?.uci, 'e8e7');
    expect(cubit.state.canMove, isTrue);

    cubit.tapSquare(Square.parse('c7'));
    cubit.tapSquare(Square.parse('a8'));
    expect(cubit.state.solved, isTrue);

    cubit.restart();
    expect(cubit.state.moveCount, 0);
    expect(cubit.state.solved, isFalse);
    await cubit.close();
  });
}
