import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../engine/chess_ai.dart';
import '../../../../engine/chess_engine.dart';
import '../../../lan/domain/lan_message.dart';
import '../../../progress/domain/game_summary.dart';
import '../../../settings/domain/app_settings.dart';
import '../../domain/chess_ai_service.dart';
import '../../domain/chess_clock.dart';
import '../../domain/coach/coach.dart';
import '../../domain/coach/coach_note.dart';
import '../../domain/game_config.dart';
import '../../domain/game_outcome.dart';
import 'game_state.dart';

/// Runs one game: applies moves, drives the computer opponent, the clock,
/// the coach, hints, predictions, the blunder guard and LAN messages.
class GameCubit extends Cubit<GameState> {
  GameCubit({
    required GameConfig config,
    required this._ai,
    required this._settings,
    this._timeSource,
    this.computerPause = const Duration(milliseconds: 450),
    Random? random,
  }) : _config = config,
       _random = random ?? Random(),
       _game = ChessGame(),
       super(
         GameState(
           config: config,
           pieces: ChessGame().pieces,
           turn: PieceColor.white,
         ),
       );

  /// Hints available per game outside learning mode.
  static const int hintLimit = 3;

  static const _maxCoachNotes = 6;

  /// Minimum time the computer appears to think, so replies feel natural.
  final Duration computerPause;

  final ChessAiService _ai;
  final TimeSource? _timeSource;
  final Random _random;

  GameConfig _config;
  AppSettings _settings;
  ChessGame _game;
  ChessClock? _clock;
  Timer? _ticker;
  Coach? _coach;
  StreamSubscription<LanMessage>? _lanSubscription;

  /// Incremented whenever pending asynchronous work becomes stale
  /// (undo, restart, game over).
  int _generation = 0;
  int _eventSerial = 0;
  bool _manualFlip = false;
  final Map<int, PositionAnalysis> _analysisByPly = {};
  final Set<int> _gradedPlies = {};

  /// Clock readings, published separately from [state] so that ticking
  /// clocks do not rebuild the whole game screen.
  final ValueNotifier<ClockReading?> clockReading = ValueNotifier(null);

  GameConfig get config => _config;

  bool get hintsUnlimited => _settings.learningMode;

  int get hintsLeft =>
      hintsUnlimited ? -1 : max(0, hintLimit - state.hintsUsed);

  /// Engine-powered assistance (hints, predictions, blunder guard) is not
  /// available in network games, to keep them fair.
  bool get _engineAssists => _config.mode != GameMode.lan;

  bool get _showPredictions => _settings.showPredictions && _engineAssists;

  bool get _localTurn =>
      _config.controlsColor(_game.turn) &&
      state.outcome == null &&
      !state.aiThinking;

  bool get _canInteract =>
      _localTurn &&
      state.pendingPromotion == null &&
      state.pendingRisky == null &&
      !state.reviewingMove;

  PositionSnapshot get _snapshot =>
      PositionSnapshot(_game.startFen, _game.uciMoves);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void start() {
    _setUp();
    final connection = _config.lanConnection;
    if (connection != null) {
      _lanSubscription = connection.messages.listen(
        _onLanMessage,
        onDone: _onLanClosed,
      );
    }
  }

  void _setUp() {
    _generation++;
    _game = ChessGame();
    _analysisByPly.clear();
    _gradedPlies.clear();
    _manualFlip = false;
    _clock?.pause();
    _ticker?.cancel();
    final control = _config.timeControl;
    _clock = control == null
        ? null
        : ChessClock(control, timeSource: _timeSource);
    if (_clock != null) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _onClockTick(),
      );
    }
    final coached = _settings.learningMode && _config.mode == GameMode.computer;
    _coach = coached ? Coach(_config.playerColor) : null;

    _publishClock();
    emit(
      GameState(
        config: _config,
        pieces: _game.pieces,
        turn: _game.turn,
        flipped: _baseFlipped(),
        coachNotes: [if (coached) WelcomeNote(_config.playerColor)],
      ),
    );
    _afterPositionChanged();
  }

  @override
  Future<void> close() async {
    _generation++;
    _ticker?.cancel();
    clockReading.dispose();
    await _lanSubscription?.cancel();
    final connection = _config.lanConnection;
    if (connection != null) {
      connection.send(const ByeMessage());
      await connection.close();
    }
    return super.close();
  }

  /// Applies changed preferences in the middle of a game.
  void updateSettings(AppSettings settings) {
    final predictionsTurnedOn =
        settings.showPredictions &&
        !_settings.showPredictions &&
        _engineAssists;
    _settings = settings;
    if (isClosed) return;
    emit(state.copyWith(dangerSquares: _dangerSquares()));
    if (predictionsTurnedOn) _requestAnalysis();
  }

  // ---------------------------------------------------------------------------
  // Player input
  // ---------------------------------------------------------------------------

  void tapSquare(int square) {
    if (!_canInteract) return;
    final selected = state.selectedSquare;
    if (selected != null) {
      if (selected == square) {
        _clearSelection();
        return;
      }
      if (state.selectedMoves.any((m) => m.to == square)) {
        _attemptMove(selected, square);
        return;
      }
    }
    _select(square);
  }

  void startDrag(int square) {
    if (!_canInteract) return;
    if (state.selectedSquare != square) _select(square);
  }

  void dropPiece(int from, int to) {
    if (!_canInteract) return;
    if (_game.legalMovesFrom(from).any((m) => m.to == to)) {
      _attemptMove(from, to);
    } else {
      _clearSelection();
    }
  }

  void _select(int square) {
    final piece = _game.pieceAt(square);
    if (piece == null || piece.color != _game.turn) {
      _clearSelection();
      return;
    }
    emit(
      state.copyWith(
        selectedSquare: () => square,
        selectedMoves: _game.legalMovesFrom(square),
      ),
    );
  }

  void _clearSelection() {
    if (state.selectedSquare == null) return;
    emit(state.copyWith(selectedSquare: () => null, selectedMoves: const []));
  }

  void _attemptMove(int from, int to) {
    final candidates = [
      for (final m in _game.legalMovesFrom(from))
        if (m.to == to) m,
    ];
    if (candidates.isEmpty) return;
    if (candidates.first.isPromotion) {
      if (_settings.autoQueen) {
        _submit(candidates.firstWhere((m) => m.promotion == PieceType.queen));
      } else {
        emit(
          state.copyWith(
            selectedSquare: () => null,
            selectedMoves: const [],
            pendingPromotion: () =>
                PendingPromotion(from: from, to: to, color: _game.turn),
          ),
        );
      }
      return;
    }
    _submit(candidates.first);
  }

  void choosePromotion(PieceType type) {
    final pending = state.pendingPromotion;
    if (pending == null) return;
    emit(state.copyWith(pendingPromotion: () => null));
    final move = _game.findMove(pending.from, pending.to, promotion: type);
    if (move != null) _submit(move);
  }

  void cancelPromotion() => emit(state.copyWith(pendingPromotion: () => null));

  Future<void> _submit(Move move) async {
    emit(state.copyWith(selectedSquare: () => null, selectedMoves: const []));
    if (_settings.blunderGuard && _engineAssists) {
      final encoded = _game.board.findMove(move.uci);
      if (encoded != null && ChessAi.needsReview(_game.board, encoded)) {
        final generation = _generation;
        emit(state.copyWith(reviewingMove: true));
        final review = await _ai.reviewMove(_snapshot, move.uci);
        if (isClosed || generation != _generation) return;
        emit(state.copyWith(reviewingMove: false));
        if (review.isBlunder) {
          emit(
            state.copyWith(
              pendingRisky: () => PendingRiskyMove(
                move: move,
                review: review,
                refutationSan: _refutationSan(move, review.refutation),
                bestSan: _sanOfUci(review.bestMove),
              ),
            ),
          );
          return;
        }
      }
    }
    _commit(move);
  }

  void confirmRiskyMove() {
    final pending = state.pendingRisky;
    if (pending == null) return;
    emit(state.copyWith(pendingRisky: () => null));
    _commit(pending.move);
  }

  void cancelRiskyMove() => emit(state.copyWith(pendingRisky: () => null));

  String? _sanOfUci(String? uci) {
    if (uci == null) return null;
    final move = _game.moveFromUci(uci);
    return move == null ? null : _game.sanOf(move);
  }

  String? _refutationSan(Move move, String? reply) {
    if (reply == null) return null;
    final line = _game.sanLine([move.uci, reply]);
    return line.length == 2 ? line[1] : null;
  }

  // ---------------------------------------------------------------------------
  // Applying moves
  // ---------------------------------------------------------------------------

  void _commit(Move move, {bool fromNetwork = false}) {
    if (state.outcome != null) return;
    final record = _game.play(move);

    final clock = _clock;
    if (clock != null) {
      if (clock.running == null) {
        clock.start(_game.turn);
      } else {
        clock.press();
      }
      _publishClock();
    }

    final connection = _config.lanConnection;
    if (connection != null && !fromNetwork) {
      connection.send(
        MoveMessage(
          uci: move.uci,
          whiteMs: clock?.remaining(PieceColor.white).inMilliseconds,
          blackMs: clock?.remaining(PieceColor.black).inMilliseconds,
        ),
      );
    }

    final notes = _coach?.afterMove(_game, record) ?? const <CoachNote>[];
    _emitPosition(newNotes: notes, clearHint: true);

    final outcome = GameOutcome.fromStatus(_game.status, _game.turn);
    if (outcome != null) {
      _finish(outcome);
      return;
    }
    _afterPositionChanged();

    if (_config.mode == GameMode.local && _settings.autoFlipBoard) {
      final generation = _generation;
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (isClosed || generation != _generation) return;
        emit(state.copyWith(flipped: _baseFlipped()));
      });
    }
  }

  void _emitPosition({
    List<CoachNote> newNotes = const [],
    bool clearHint = false,
  }) {
    final king = _game.isCheck ? _game.kingSquare(_game.turn) : null;
    final notes = [...newNotes.reversed, ...state.coachNotes];
    emit(
      state.copyWith(
        pieces: _game.pieces,
        turn: _game.turn,
        moveCount: _game.history.length,
        history: _game.history,
        lastMove: () => _game.lastMove,
        checkSquare: () => king,
        whiteCaptured: _game.capturedPieces(PieceColor.black),
        blackCaptured: _game.capturedPieces(PieceColor.white),
        materialBalance: _game.materialBalance,
        selectedSquare: () => null,
        selectedMoves: const [],
        coachNotes: notes.take(_maxCoachNotes).toList(),
        hint: clearHint ? () => null : null,
        analysis: () => null,
        predictedLine: const [],
        dangerSquares: _dangerSquares(),
        canUndo: _canUndo(),
        threatSan: () => null,
      ),
    );
  }

  void _afterPositionChanged() {
    if (state.outcome != null) return;
    if (_showPredictions || _coach != null) _requestAnalysis();
    if (_config.mode == GameMode.computer &&
        _game.turn != _config.playerColor) {
      _requestComputerMove();
    }
  }

  bool _baseFlipped() {
    final base = switch (_config.mode) {
      GameMode.local =>
        _settings.autoFlipBoard && _game.turn == PieceColor.black,
      _ => _config.playerColor == PieceColor.black,
    };
    return base != _manualFlip;
  }

  void flipBoard() {
    _manualFlip = !_manualFlip;
    emit(state.copyWith(flipped: _baseFlipped()));
  }

  List<int> _dangerSquares() {
    if (!_settings.highlightThreats || state.outcome != null) return const [];
    final side = _config.mode == GameMode.local
        ? _game.turn
        : _config.playerColor;
    if (_game.turn != side) return const [];
    return Tactics.hangingPieces(_game.board, side.sign);
  }

  bool _canUndo() {
    if (!_settings.allowUndo || _config.mode == GameMode.lan) return false;
    if (_config.mode == GameMode.local) return _game.canUndo;
    return _game.history.any((r) => r.color == _config.playerColor);
  }

  // ---------------------------------------------------------------------------
  // Computer opponent, analysis and hints
  // ---------------------------------------------------------------------------

  Future<void> _requestComputerMove() async {
    final level = _config.aiLevel;
    if (level == null) return;
    final generation = _generation;
    emit(state.copyWith(aiThinking: true));
    final started = DateTime.now();
    final move = await _ai.chooseMove(_snapshot, level.skill);
    // A short pause feels more natural than an instant reply.
    final pauseMs = computerPause.inMilliseconds;
    final minimum = Duration(
      milliseconds: pauseMs + _random.nextInt(pauseMs + 1),
    );
    final elapsed = DateTime.now().difference(started);
    if (elapsed < minimum) await Future<void>.delayed(minimum - elapsed);
    if (isClosed || generation != _generation) return;
    emit(state.copyWith(aiThinking: false));
    final legal = move == null ? null : _game.moveFromUci(move.uci);
    if (legal != null) _commit(legal);
  }

  Future<void> _requestAnalysis() async {
    final generation = _generation;
    final ply = _game.history.length;
    final strength = _coach != null && !_showPredictions
        ? AnalysisStrength.quick
        : AnalysisStrength.normal;
    final analysis = await _ai.analyze(_snapshot, strength: strength);
    if (isClosed || generation != _generation) return;
    _analysisByPly[ply] = analysis;
    _gradePendingMoves();
    if (ply == _game.history.length && state.outcome == null) {
      emit(
        state.copyWith(
          analysis: () => analysis,
          predictedLine: _game.sanLine(
            analysis.principalVariation.take(6).toList(),
          ),
          threatSan: () => _threatSan(analysis.threat),
        ),
      );
    }
  }

  /// Notation for a move the opponent would play if it were their turn.
  String? _threatSan(String? uci) {
    if (uci == null) return null;
    final board = _game.board..makeNullMove();
    final encoded = board.findMove(uci);
    String? san;
    if (encoded != null) {
      final move = board.decode(encoded);
      final from = move.piece.type == PieceType.pawn && move.isCapture
          ? Square.fileName(move.from)
          : '';
      san =
          '${move.piece.type.sanLetter}$from${move.isCapture ? 'x' : ''}'
          '${Square.name(move.to)}';
    }
    board.unmakeNullMove();
    return san;
  }

  /// Grades learner moves once analyses before and after them are known.
  void _gradePendingMoves() {
    final coach = _coach;
    if (coach == null) return;
    final history = _game.history;
    for (final ply in _analysisByPly.keys.toList()..sort()) {
      if (ply == 0 || _gradedPlies.contains(ply) || ply > history.length) {
        continue;
      }
      final record = history[ply - 1];
      if (record.color != coach.learner) continue;
      final before = _analysisByPly[ply - 1];
      final after = _analysisByPly[ply];
      if (before == null || after == null) continue;
      _gradedPlies.add(ply);
      final best = before.bestMove;
      String? bestSan;
      if (best != null && best != record.move.uci) {
        final replay = ChessGame.fromMoves(
          _game.uciMoves.take(ply - 1).toList(),
          startFen: _game.startFen,
        );
        final bestMove = replay.moveFromUci(best);
        if (bestMove != null) bestSan = replay.sanOf(bestMove);
      }
      final note = Coach.grade(
        mover: record.color,
        before: before,
        after: after,
        playedUci: record.move.uci,
        bestSan: bestSan,
      );
      emit(
        state.copyWith(
          coachNotes: [note, ...state.coachNotes].take(_maxCoachNotes).toList(),
        ),
      );
    }
  }

  Future<void> requestHint() async {
    if (!_canInteract || state.hintLoading || !_engineAssists) return;
    if (!hintsUnlimited && state.hintsUsed >= hintLimit) {
      _emitEvent(GameEventKind.hintLimitReached);
      return;
    }
    final generation = _generation;
    emit(state.copyWith(hintLoading: true));
    final analysis = await _ai.analyze(
      _snapshot,
      strength: AnalysisStrength.normal,
    );
    if (isClosed || generation != _generation) return;
    final best = analysis.bestMove;
    final move = best == null ? null : _game.moveFromUci(best);
    if (move == null) {
      emit(state.copyWith(hintLoading: false));
      return;
    }
    final san = _game.sanOf(move);
    final note = Coach.explainHint(_game, move, san, analysis);
    emit(
      state.copyWith(
        hintLoading: false,
        hint: () => Hint(move, note),
        hintsUsed: state.hintsUsed + 1,
        coachNotes: [note, ...state.coachNotes].take(_maxCoachNotes).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Game actions
  // ---------------------------------------------------------------------------

  void undo() {
    if (!_canUndo() || state.outcome != null) return;
    _generation++;
    if (_config.mode == GameMode.computer) {
      // Take back the computer's reply as well as the player's move.
      while (_game.canUndo) {
        final last = _game.history.last;
        _game.undo();
        if (last.color == _config.playerColor) break;
      }
    } else {
      _game.undo();
    }
    _analysisByPly.removeWhere((ply, _) => ply > _game.history.length);
    _gradedPlies.removeWhere((ply) => ply > _game.history.length);
    if (_clock?.running != null) {
      _clock!.start(_game.turn);
      _publishClock();
    }
    emit(
      state.copyWith(
        aiThinking: false,
        reviewingMove: false,
        hintLoading: false,
        pendingPromotion: () => null,
        pendingRisky: () => null,
        undosUsed: state.undosUsed + 1,
      ),
    );
    _emitPosition(clearHint: true);
    if (_config.mode == GameMode.local) {
      emit(state.copyWith(flipped: _baseFlipped()));
    }
    _afterPositionChanged();
  }

  void resign() {
    if (state.outcome != null) return;
    final loser = _config.mode == GameMode.local
        ? _game.turn
        : _config.playerColor;
    _config.lanConnection?.send(const ResignMessage());
    _finish(
      GameOutcome(reason: OutcomeReason.resignation, winner: loser.opposite),
    );
  }

  /// Offers a draw. Against the computer the answer is immediate; on the
  /// same device both players are present, so the draw is agreed directly.
  Future<void> offerDraw() async {
    if (state.outcome != null) return;
    switch (_config.mode) {
      case GameMode.local:
        _finish(const GameOutcome(reason: OutcomeReason.agreement));
      case GameMode.lan:
        _config.lanConnection?.send(const DrawOfferMessage());
        emit(state.copyWith(drawOfferPending: true));
      case GameMode.computer:
        final generation = _generation;
        final analysis =
            state.analysis ??
            await _ai.analyze(_snapshot, strength: AnalysisStrength.quick);
        if (isClosed || generation != _generation) return;
        final computerScore =
            analysis.scoreWhite * _config.playerColor.opposite.sign;
        if (_game.history.length >= 20 && computerScore <= 30) {
          _finish(const GameOutcome(reason: OutcomeReason.agreement));
        } else {
          _emitEvent(GameEventKind.drawDeclined);
        }
    }
  }

  void answerDrawOffer({required bool accept}) {
    if (!state.drawOfferedByOpponent) return;
    _config.lanConnection?.send(DrawReplyMessage(accepted: accept));
    emit(state.copyWith(drawOfferedByOpponent: false));
    if (accept) _finish(const GameOutcome(reason: OutcomeReason.agreement));
  }

  void sendReaction(String emoji) =>
      _config.lanConnection?.send(ReactionMessage(emoji));

  /// Starts a new game. Network games swap colours and need the
  /// opponent's agreement first (see [offerRematch]).
  void restart({bool swapColors = false}) {
    if (swapColors) _config = _config.swapColors();
    _setUp();
  }

  void offerRematch() {
    final connection = _config.lanConnection;
    if (connection == null) return;
    connection.send(const RematchOfferMessage());
    emit(state.copyWith(rematchOfferPending: true));
  }

  void answerRematch({required bool accept}) {
    _config.lanConnection?.send(RematchReplyMessage(accepted: accept));
    emit(state.copyWith(rematchOfferedByOpponent: false));
    if (accept) restart(swapColors: true);
  }

  void _finish(GameOutcome outcome) {
    _generation++;
    _clock?.pause();
    _ticker?.cancel();
    emit(
      state.copyWith(
        outcome: () => outcome,
        aiThinking: false,
        reviewingMove: false,
        hintLoading: false,
        selectedSquare: () => null,
        selectedMoves: const [],
        pendingPromotion: () => null,
        pendingRisky: () => null,
        dangerSquares: const [],
        canUndo: false,
      ),
    );
    _publishClock();
  }

  void _emitEvent(GameEventKind kind, {String? payload}) {
    emit(
      state.copyWith(
        event: () => GameEvent(kind, ++_eventSerial, payload: payload),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  void _publishClock() {
    final clock = _clock;
    clockReading.value = clock == null
        ? null
        : ClockReading(
            white: clock.remaining(PieceColor.white),
            black: clock.remaining(PieceColor.black),
            running: clock.running,
          );
  }

  void _onClockTick() {
    final clock = _clock;
    if (clock == null || isClosed || state.outcome != null) return;
    final running = clock.running;
    if (running == null) return;
    _publishClock();
    if (clock.isFlagged(running)) {
      // On the network each device decides only its own flag.
      if (_config.mode == GameMode.lan && running != _config.playerColor) {
        return;
      }
      _config.lanConnection?.send(const TimeoutMessage());
      _finishOnTime(running);
    }
  }

  void _finishOnTime(PieceColor flagged) {
    final winner = flagged.opposite;
    _finish(
      GameOutcome(
        reason: OutcomeReason.timeout,
        winner: _game.hasMatingMaterial(winner) ? winner : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------------------

  void _onLanMessage(LanMessage message) {
    if (isClosed) return;
    switch (message) {
      case MoveMessage(:final uci, :final whiteMs, :final blackMs):
        if (state.outcome != null || _game.turn == _config.playerColor) return;
        final move = _game.moveFromUci(uci);
        if (move == null) return;
        _commit(move, fromNetwork: true);
        final clock = _clock;
        if (clock != null && whiteMs != null && blackMs != null) {
          clock
            ..setRemaining(PieceColor.white, Duration(milliseconds: whiteMs))
            ..setRemaining(PieceColor.black, Duration(milliseconds: blackMs));
          _publishClock();
        }
      case ResignMessage():
        _finish(
          GameOutcome(
            reason: OutcomeReason.resignation,
            winner: _config.playerColor,
          ),
        );
      case DrawOfferMessage():
        if (state.outcome != null) return;
        emit(state.copyWith(drawOfferedByOpponent: true));
        _emitEvent(GameEventKind.drawOffered);
      case DrawReplyMessage(:final accepted):
        emit(state.copyWith(drawOfferPending: false));
        if (accepted) {
          _finish(const GameOutcome(reason: OutcomeReason.agreement));
        } else {
          _emitEvent(GameEventKind.drawDeclined);
        }
      case RematchOfferMessage():
        emit(state.copyWith(rematchOfferedByOpponent: true));
      case RematchReplyMessage(:final accepted):
        emit(state.copyWith(rematchOfferPending: false));
        if (accepted) {
          restart(swapColors: true);
        } else {
          _emitEvent(GameEventKind.rematchDeclined);
        }
      case ReactionMessage(:final emoji):
        _emitEvent(GameEventKind.reaction, payload: emoji);
      case TimeoutMessage():
        if (state.outcome == null) _finishOnTime(_config.playerColor.opposite);
      case ByeMessage():
        _onLanClosed();
      case HelloMessage() || WelcomeMessage():
        break;
    }
  }

  void _onLanClosed() {
    if (isClosed) return;
    _emitEvent(GameEventKind.opponentLeft);
    if (state.outcome == null) {
      _finish(
        GameOutcome(
          reason: OutcomeReason.opponentLeft,
          winner: _config.playerColor,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Results
  // ---------------------------------------------------------------------------

  /// The finished game from the local player's perspective, for rewards.
  GameSummary? summary() {
    final outcome = state.outcome;
    if (outcome == null) return null;
    final local = _config.mode == GameMode.local;
    final player = _config.playerColor;
    final mine = [
      for (final r in _game.history)
        if (local || r.color == player) r.move,
    ];
    final PlayerResult? result;
    if (local) {
      result = null;
    } else if (outcome.isDraw) {
      result = PlayerResult.draw;
    } else {
      result = outcome.winner == player ? PlayerResult.win : PlayerResult.loss;
    }
    return GameSummary(
      mode: switch (_config.mode) {
        GameMode.computer => PlayedMode.computer,
        GameMode.local => PlayedMode.local,
        GameMode.lan => PlayedMode.lan,
      },
      result: result,
      aiLevel: _config.aiLevel?.number,
      byCheckmate: outcome.reason == OutcomeReason.checkmate,
      playerMoves: local ? (mine.length / 2).ceil() : mine.length,
      hintsUsed: state.hintsUsed,
      undosUsed: state.undosUsed,
      castled: mine.any((m) => m.isCastle),
      promoted: mine.any((m) => m.isPromotion),
      enPassant: mine.any((m) => m.isEnPassant),
    );
  }
}
