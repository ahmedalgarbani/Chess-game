import 'dart:async';

import 'package:chess_game/engine/chess_ai.dart';
import 'package:chess_game/engine/chess_engine.dart';
import 'package:chess_game/features/game/domain/ai_level.dart';
import 'package:chess_game/features/game/domain/chess_ai_service.dart';
import 'package:chess_game/features/game/domain/coach/coach_note.dart';
import 'package:chess_game/features/game/domain/game_config.dart';
import 'package:chess_game/features/game/domain/game_outcome.dart';
import 'package:chess_game/features/game/domain/game_snapshot.dart';
import 'package:chess_game/features/game/domain/hint_wallet.dart';
import 'package:chess_game/features/game/presentation/cubit/game_cubit.dart';
import 'package:chess_game/features/progress/domain/game_summary.dart';
import 'package:chess_game/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// A deterministic engine: plays the first legal move, analyses statically.
class FakeAi implements ChessAiService {
  MoveReview review = const MoveReview(
    lossCp: 0,
    bestMove: null,
    refutation: null,
    allowsMate: false,
  );
  int reviews = 0;

  @override
  Future<EngineMove?> chooseMove(
    PositionSnapshot position,
    EngineSkill skill,
  ) async {
    final board = ChessAi.replay(position.startFen, position.moves);
    final moves = board.legalMoves();
    if (moves.isEmpty) return null;
    return EngineMove(uci: board.decode(moves.first).uci, score: 0);
  }

  @override
  Future<PositionAnalysis> analyze(
    PositionSnapshot position, {
    AnalysisStrength strength = AnalysisStrength.normal,
  }) async {
    final board = ChessAi.replay(position.startFen, position.moves);
    return ChessAi.analyze(board, maxDepth: 2, timeLimitMs: 200);
  }

  @override
  Future<MoveReview> reviewMove(PositionSnapshot position, String uci) async {
    reviews++;
    return review;
  }
}

/// An engine that always fails, to check the game never gets stuck.
class BrokenAi extends FakeAi {
  @override
  Future<EngineMove?> chooseMove(
    PositionSnapshot position,
    EngineSkill skill,
  ) => Future.error(StateError('engine crashed'));

  @override
  Future<PositionAnalysis> analyze(
    PositionSnapshot position, {
    AnalysisStrength strength = AnalysisStrength.normal,
  }) => Future.error(StateError('engine crashed'));
}

/// An engine whose analysis completes only when the test says so.
class SlowAi extends FakeAi {
  final pending = <Completer<PositionAnalysis>>[];

  @override
  Future<PositionAnalysis> analyze(
    PositionSnapshot position, {
    AnalysisStrength strength = AnalysisStrength.normal,
  }) {
    final completer = Completer<PositionAnalysis>();
    pending.add(completer);
    return completer.future;
  }
}

/// Purchased hints held in memory.
class FakeWallet implements HintWallet {
  FakeWallet(this.balance);

  @override
  int balance;

  @override
  bool spend() {
    if (balance == 0) return false;
    balance--;
    return true;
  }
}

int sq(String name) => Square.parse(name);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

GameCubit makeCubit(
  GameConfig config, {
  AppSettings settings = const AppSettings(learningMode: false),
  FakeAi? ai,
  HintWallet? wallet,
  GameSnapshot? resumeFrom,
}) {
  return GameCubit(
    config: config,
    ai: ai ?? FakeAi(),
    settings: settings,
    computerPause: Duration.zero,
    hintWallet: wallet,
    resumeFrom: resumeFrom,
  )..start();
}

void main() {
  test('tap to select and move in a local game', () async {
    final cubit = makeCubit(const GameConfig(mode: GameMode.local));
    cubit.tapSquare(sq('e2'));
    expect(cubit.state.selectedSquare, sq('e2'));
    expect(
      cubit.state.selectedMoves.map((m) => m.to),
      containsAll([sq('e3'), sq('e4')]),
    );
    cubit.tapSquare(sq('e4'));
    await settle();
    expect(cubit.state.moveCount, 1);
    expect(cubit.state.turn, PieceColor.black);
    expect(cubit.state.history.single.san, 'e4');
    await cubit.close();
  });

  test('the computer replies and undo takes back both moves', () async {
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
    );
    cubit.dropPiece(sq('d2'), sq('d4'));
    await settle();
    await settle();
    expect(cubit.state.moveCount, 2);
    expect(cubit.state.turn, PieceColor.white);
    expect(cubit.state.canUndo, isTrue);

    cubit.undo();
    await settle();
    expect(cubit.state.moveCount, 0);
    expect(cubit.state.undosUsed, 1);
    await cubit.close();
  });

  test('the computer opens when the player takes black', () async {
    final cubit = makeCubit(
      GameConfig(
        mode: GameMode.computer,
        playerColor: PieceColor.black,
        aiLevel: AiLevel.byNumber(1),
      ),
    );
    await settle();
    expect(cubit.state.moveCount, 1);
    expect(cubit.state.flipped, isTrue);
    await cubit.close();
  });

  test('promotion waits for the piece choice', () async {
    final cubit = makeCubit(const GameConfig(mode: GameMode.local));
    // Play a quick sequence that lets a white pawn reach the 7th rank.
    for (final (from, to) in [
      ('h2', 'h4'),
      ('g7', 'g5'),
      ('h4', 'g5'),
      ('h7', 'h6'),
      ('g5', 'h6'),
      ('a7', 'a6'),
      ('h6', 'h7'),
      ('a6', 'a5'),
    ]) {
      cubit.dropPiece(sq(from), sq(to));
      await settle();
    }
    cubit.dropPiece(sq('h7'), sq('g8'));
    expect(cubit.state.pendingPromotion, isNotNull);
    cubit.choosePromotion(PieceType.knight);
    await settle();
    expect(cubit.state.pieces[sq('g8')], Piece.whiteKnight);
    await cubit.close();
  });

  test('the blunder guard asks before a losing move', () async {
    final ai = FakeAi()
      ..review = const MoveReview(
        lossCp: 900,
        bestMove: 'e2e4',
        refutation: 'g8f6',
        allowsMate: false,
      );
    final cubit = makeCubit(
      const GameConfig(mode: GameMode.local),
      settings: const AppSettings(learningMode: false, blunderGuard: true),
      ai: ai,
    );
    // 1. e4 Nf6 2. Qh5?? hangs the queen to the knight.
    for (final (from, to) in [('e2', 'e4'), ('g8', 'f6')]) {
      cubit.dropPiece(sq(from), sq(to));
      await settle();
    }
    cubit.dropPiece(sq('d1'), sq('h5'));
    await settle();
    expect(ai.reviews, 1);
    expect(cubit.state.pendingRisky, isNotNull);
    expect(cubit.state.moveCount, 2);
    cubit.cancelRiskyMove();
    expect(cubit.state.pendingRisky, isNull);

    cubit.dropPiece(sq('d1'), sq('h5'));
    await settle();
    cubit.confirmRiskyMove();
    await settle();
    expect(cubit.state.moveCount, 3);
    await cubit.close();
  });

  test('checkmate ends the game and produces a summary', () async {
    final cubit = makeCubit(const GameConfig(mode: GameMode.local));
    for (final (from, to) in [
      ('f2', 'f3'),
      ('e7', 'e5'),
      ('g2', 'g4'),
      ('d8', 'h4'),
    ]) {
      cubit.dropPiece(sq(from), sq(to));
      await settle();
    }
    final outcome = cubit.state.outcome!;
    expect(outcome.reason, OutcomeReason.checkmate);
    expect(outcome.winner, PieceColor.black);
    final summary = cubit.summary()!;
    expect(summary.mode, PlayedMode.local);
    expect(summary.result, isNull);
    expect(summary.byCheckmate, isTrue);
    await cubit.close();
  });

  test('hints are limited outside learning mode', () async {
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
    );
    for (var i = 0; i < GameCubit.hintLimit; i++) {
      await cubit.requestHint();
      expect(cubit.state.hint, isNotNull);
    }
    expect(cubit.hintsLeft, 0);
    await cubit.requestHint();
    expect(cubit.state.hintsUsed, GameCubit.hintLimit);
    await cubit.close();
  });

  test('purchased hints are spent after the free ones', () async {
    final wallet = FakeWallet(2);
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
      wallet: wallet,
    );
    expect(cubit.hintsLeft, GameCubit.hintLimit + 2);
    for (var i = 0; i < GameCubit.hintLimit; i++) {
      await cubit.requestHint();
    }
    expect(wallet.balance, 2);
    await cubit.requestHint();
    expect(wallet.balance, 1);
    expect(cubit.state.hintsUsed, GameCubit.hintLimit + 1);
    await cubit.requestHint();
    expect(wallet.balance, 0);
    expect(cubit.hintsLeft, 0);
    await cubit.requestHint();
    expect(cubit.state.hintsUsed, GameCubit.hintLimit + 2);
    await cubit.close();
  });

  test('learning mode never spends purchased hints', () async {
    final wallet = FakeWallet(1);
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
      settings: const AppSettings(learningMode: true),
      wallet: wallet,
    );
    for (var i = 0; i < GameCubit.hintLimit + 2; i++) {
      await cubit.requestHint();
    }
    expect(wallet.balance, 1);
    await cubit.close();
  });

  test('the coach explains moves in learning mode', () async {
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
      settings: const AppSettings(learningMode: true),
    );
    expect(cubit.state.coachNotes.single, isA<WelcomeNote>());
    cubit.dropPiece(sq('g1'), sq('f3'));
    await settle();
    expect(
      cubit.state.coachNotes.whereType<PieceIntroNote>().first.type,
      PieceType.knight,
    );
    expect(cubit.hintsLeft, -1);
    await cubit.close();
  });

  test('resigning gives the game to the opponent', () async {
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
    );
    cubit.resign();
    expect(cubit.state.outcome!.winner, PieceColor.black);
    expect(cubit.summary()!.result, PlayerResult.loss);
    await cubit.close();
  });

  test('a failing engine still lets the computer move', () async {
    final cubit = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
      ai: BrokenAi(),
    );
    cubit.dropPiece(sq('e2'), sq('e4'));
    await settle();
    await settle();
    expect(cubit.state.moveCount, 2);
    expect(cubit.state.aiThinking, isFalse);
    await cubit.requestHint();
    expect(cubit.state.hintLoading, isFalse);
    expect(cubit.state.hint, isNull);
    await cubit.close();
  });

  test('a hint computed for an old position is discarded', () async {
    final ai = SlowAi();
    final cubit = makeCubit(const GameConfig(mode: GameMode.local), ai: ai);
    final hint = cubit.requestHint();
    cubit.dropPiece(sq('e2'), sq('e4'));
    await settle();
    final board = ChessAi.replay(startingFen, const []);
    ai.pending.first.complete(ChessAi.analyze(board, maxDepth: 1));
    await hint;
    expect(cubit.state.hint, isNull);
    expect(cubit.state.hintsUsed, 0);
    await cubit.close();
  });

  test('an unfinished game can be saved and resumed', () async {
    final config = GameConfig(
      mode: GameMode.computer,
      aiLevel: AiLevel.byNumber(1),
      timeControl: const TimeControl(5),
    );
    final cubit = makeCubit(config);
    expect(cubit.snapshot(), isNull);
    cubit.dropPiece(sq('e2'), sq('e4'));
    await settle();
    await settle();
    await cubit.requestHint();
    final snapshot = cubit.snapshot()!;
    expect(snapshot.moves, hasLength(2));
    expect(snapshot.hintsUsed, 1);
    expect(snapshot.whiteTime, isNotNull);
    await cubit.close();

    final resumed = makeCubit(
      snapshot.config,
      resumeFrom: GameSnapshot(
        config: snapshot.config,
        moves: snapshot.moves,
        savedAt: snapshot.savedAt,
        whiteTime: const Duration(minutes: 2),
        blackTime: const Duration(minutes: 4),
        hintsUsed: snapshot.hintsUsed,
      ),
    );
    expect(resumed.state.moveCount, 2);
    expect(resumed.state.turn, PieceColor.white);
    expect(resumed.state.history.first.san, 'e4');
    expect(resumed.state.hintsUsed, 1);
    expect(resumed.clockReading.value?.running, PieceColor.white);
    expect(resumed.clockReading.value!.black, const Duration(minutes: 4));
    expect(resumed.moves, snapshot.moves);

    // Starting over forgets the saved moves.
    resumed.restart();
    expect(resumed.state.moveCount, 0);
    expect(resumed.snapshot(), isNull);
    await resumed.close();
  });

  test('resuming with the computer to move lets it play', () async {
    final resumed = makeCubit(
      GameConfig(mode: GameMode.computer, aiLevel: AiLevel.byNumber(1)),
      resumeFrom: GameSnapshot(
        config: GameConfig(
          mode: GameMode.computer,
          aiLevel: AiLevel.byNumber(1),
        ),
        moves: const ['e2e4'],
        savedAt: DateTime(2026),
      ),
    );
    await settle();
    await settle();
    expect(resumed.state.moveCount, 2);
    await resumed.close();
  });

  test('finished games are not saved for later', () async {
    final cubit = makeCubit(const GameConfig(mode: GameMode.local));
    cubit.dropPiece(sq('e2'), sq('e4'));
    await settle();
    expect(cubit.snapshot(), isNotNull);
    cubit.resign();
    expect(cubit.snapshot(), isNull);
    await cubit.close();
  });
}
