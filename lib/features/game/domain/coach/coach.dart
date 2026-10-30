import '../../../../engine/chess_ai.dart';
import '../../../../engine/chess_engine.dart';
import 'coach_note.dart';

/// Explains moves to a learner in plain language: what happened, what is
/// attacked, which opening principles apply and how good the move was.
class Coach {
  Coach(this.learner);

  /// The colour of the player being coached.
  final PieceColor learner;

  final Set<PieceType> _introduced = {};
  final Set<OpeningTip> _tipsGiven = {};

  static const _centerSquares = {
    'd4',
    'e4',
    'd5',
    'e5',
    'c4',
    'c5',
    'f4',
    'f5',
  };

  /// Notes for the move in [record], which has just been played in [game].
  List<CoachNote> afterMove(ChessGame game, MoveRecord record) {
    final move = record.move;
    final byLearner = move.piece.color == learner;
    final notes = <CoachNote>[];

    if (byLearner && _introduced.add(move.piece.type)) {
      notes.add(PieceIntroNote(move.piece.type));
    }
    if (!byLearner) notes.add(MoveDescriptionNote(move, byLearner: false));

    if (move.isCastle) {
      notes.add(
        CastlingNote(
          kingside: move.kind == MoveKind.castleKingside,
          byLearner: byLearner,
        ),
      );
    }
    if (move.isEnPassant) notes.add(EnPassantNote(byLearner: byLearner));
    if (move.promotion != null) {
      notes.add(PromotionNote(move.promotion!, byLearner: byLearner));
    }
    final captured = move.captured;
    if (captured != null && !move.isEnPassant) {
      notes.add(CaptureNote(captured.type, byLearner: byLearner));
    }
    if (game.isCheck && !game.isGameOver) {
      notes.add(CheckNote(byLearner: byLearner));
    }

    final targets = _targets(game, move.to);
    if (targets.isNotEmpty) {
      notes.add(
        AttackNote(
          move.promotion ?? move.piece.type,
          targets,
          byLearner: byLearner,
        ),
      );
    }

    final hanging = [
      for (final square in Tactics.hangingPieces(game.board, learner.sign))
        if (game.pieceAt(square) case final piece?)
          (type: piece.type, square: square),
    ];
    if (hanging.isNotEmpty && !game.isGameOver) notes.add(HangingNote(hanging));

    if (byLearner) {
      final tip = _openingTip(game, record);
      if (tip != null) notes.add(OpeningTipNote(tip));
    }
    return notes;
  }

  List<PlacedPiece> _targets(ChessGame game, int square) => [
    for (final target in Tactics.targetsOfPiece(game.board, square))
      if (game.pieceAt(target) case final piece?)
        (type: piece.type, square: target),
  ];

  OpeningTip? _openingTip(ChessGame game, MoveRecord record) {
    if (record.moveNumber > 12) return null;
    final move = record.move;
    final history = game.history;
    final learnerMoves = [
      for (final r in history)
        if (r.move.piece.color == learner) r.move,
    ];

    OpeningTip? give(OpeningTip tip) => _tipsGiven.add(tip) ? tip : null;

    if (learnerMoves.length == 1) {
      final central =
          move.piece.type == PieceType.pawn &&
          _centerSquares.contains(Square.name(move.to));
      if (!central && move.piece.type != PieceType.knight) {
        return give(OpeningTip.controlCenter);
      }
    }
    if (move.piece.type == PieceType.queen && record.moveNumber <= 5) {
      return give(OpeningTip.queenTooEarly);
    }
    if (learnerMoves.length >= 2 && !move.isCapture) {
      final previous = learnerMoves[learnerMoves.length - 2];
      if (previous.to == move.from &&
          move.piece.type != PieceType.pawn &&
          record.moveNumber <= 8) {
        return give(OpeningTip.samePieceTwice);
      }
    }
    final castled = learnerMoves.any((m) => m.isCastle);
    if (!castled && record.moveNumber >= 8) {
      final king = game.kingSquare(learner);
      final home = learner == PieceColor.white ? 'e1' : 'e8';
      if (king != null && Square.name(king) == home) {
        return give(OpeningTip.castleEarly);
      }
    }
    if (record.moveNumber == 4) {
      final backRank = learner == PieceColor.white ? 0 : 7;
      final undeveloped = [
        for (final file in const [1, 2, 5, 6])
          if (game.pieceAt(Square.at(file, backRank)) case final piece?
              when piece.color == learner &&
                  (piece.type == PieceType.knight ||
                      piece.type == PieceType.bishop))
            file,
      ];
      if (undeveloped.length >= 3) return give(OpeningTip.developPieces);
    }
    return null;
  }

  /// Grades a learner move by comparing evaluations (white's point of view)
  /// before and after it.
  static MoveQualityNote grade({
    required PieceColor mover,
    required PositionAnalysis before,
    required PositionAnalysis after,
    required String playedUci,
    String? bestSan,
  }) {
    final sign = mover.sign;
    final loss = (before.scoreWhite - after.scoreWhite) * sign;
    final quality = switch (loss) {
      _ when before.bestMove == playedUci => MoveQuality.best,
      <= 15 => MoveQuality.best,
      <= 50 => MoveQuality.good,
      <= 120 => MoveQuality.inaccuracy,
      <= 280 => MoveQuality.mistake,
      _ => MoveQuality.blunder,
    };
    final showBetter = quality.index >= MoveQuality.inaccuracy.index;
    return MoveQualityNote(quality, betterSan: showBetter ? bestSan : null);
  }

  /// Explains why [move] is a good suggestion.
  static HintNote explainHint(
    ChessGame game,
    Move move,
    String san,
    PositionAnalysis analysis,
  ) {
    final side = game.turn;
    final mateIn = analysis.mateIn;
    if (mateIn != null && mateIn * side.sign > 0) {
      return HintNote(san, HintReason.mate, mateIn: mateIn.abs());
    }
    if (move.promotion != null) return HintNote(san, HintReason.promotes);
    final captured = move.captured;
    if (captured != null) {
      final defended = game.board.isAttacked(
        Square.to0x88(move.to),
        -side.sign,
      );
      if (!defended || captured.type.value > move.piece.type.value) {
        return HintNote(san, HintReason.winsMaterial);
      }
    }
    if (move.isCastle) return HintNote(san, HintReason.castles);
    if (Tactics.hangingPieces(game.board, side.sign).contains(move.from)) {
      return HintNote(san, HintReason.savesPiece);
    }
    if (san.endsWith('+')) return HintNote(san, HintReason.givesCheck);
    if (game.fullmoveNumber <= 12) {
      final backRank = side == PieceColor.white ? 0 : 7;
      final minor =
          move.piece.type == PieceType.knight ||
          move.piece.type == PieceType.bishop;
      if (minor && Square.rank(move.from) == backRank) {
        return HintNote(san, HintReason.develops);
      }
      if (move.piece.type == PieceType.pawn &&
          _centerSquares.contains(Square.name(move.to))) {
        return HintNote(san, HintReason.controlsCenter);
      }
    }
    return HintNote(san, HintReason.improves);
  }
}
