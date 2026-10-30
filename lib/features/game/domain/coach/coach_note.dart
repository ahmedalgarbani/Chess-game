import '../../../../engine/chess_engine.dart';

/// The mood of a coach message, which decides its colour and icon.
enum CoachTone { info, tip, praise, warning, danger }

enum OpeningTip {
  controlCenter,
  developPieces,
  castleEarly,
  queenTooEarly,
  samePieceTwice,
}

enum MoveQuality { best, good, inaccuracy, mistake, blunder }

/// Why a hint move is good.
enum HintReason {
  mate,
  winsMaterial,
  savesPiece,
  castles,
  develops,
  controlsCenter,
  promotes,
  givesCheck,
  improves,
}

/// A piece on a square, used to describe threats.
typedef PlacedPiece = ({PieceType type, int square});

/// Structured coach messages. The presentation layer turns them into
/// localized sentences, so the coaching logic stays testable.
sealed class CoachNote {
  const CoachNote();

  CoachTone get tone;
}

/// Shown at the start of a game for learners.
class WelcomeNote extends CoachNote {
  const WelcomeNote(this.learnerColor);

  final PieceColor learnerColor;

  @override
  CoachTone get tone => CoachTone.info;
}

/// How a piece moves, shown the first time the learner moves it.
class PieceIntroNote extends CoachNote {
  const PieceIntroNote(this.type);

  final PieceType type;

  @override
  CoachTone get tone => CoachTone.info;
}

/// A plain description of the move that was just played.
class MoveDescriptionNote extends CoachNote {
  const MoveDescriptionNote(this.move, {required this.byLearner});

  final Move move;
  final bool byLearner;

  @override
  CoachTone get tone => CoachTone.info;
}

class CaptureNote extends CoachNote {
  const CaptureNote(this.captured, {required this.byLearner});

  final PieceType captured;
  final bool byLearner;

  @override
  CoachTone get tone => byLearner ? CoachTone.praise : CoachTone.warning;
}

class CheckNote extends CoachNote {
  const CheckNote({required this.byLearner});

  final bool byLearner;

  @override
  CoachTone get tone => byLearner ? CoachTone.praise : CoachTone.danger;
}

class CastlingNote extends CoachNote {
  const CastlingNote({required this.kingside, required this.byLearner});

  final bool kingside;
  final bool byLearner;

  @override
  CoachTone get tone => byLearner ? CoachTone.praise : CoachTone.info;
}

class EnPassantNote extends CoachNote {
  const EnPassantNote({required this.byLearner});

  final bool byLearner;

  @override
  CoachTone get tone => CoachTone.info;
}

class PromotionNote extends CoachNote {
  const PromotionNote(this.promotedTo, {required this.byLearner});

  final PieceType promotedTo;
  final bool byLearner;

  @override
  CoachTone get tone => byLearner ? CoachTone.praise : CoachTone.warning;
}

/// The piece that just moved now attacks valuable or loose pieces.
class AttackNote extends CoachNote {
  const AttackNote(this.attacker, this.targets, {required this.byLearner});

  final PieceType attacker;
  final List<PlacedPiece> targets;
  final bool byLearner;

  @override
  CoachTone get tone => byLearner ? CoachTone.tip : CoachTone.warning;
}

/// The learner's pieces that are attacked and insufficiently defended.
class HangingNote extends CoachNote {
  const HangingNote(this.pieces);

  final List<PlacedPiece> pieces;

  @override
  CoachTone get tone => CoachTone.warning;
}

class OpeningTipNote extends CoachNote {
  const OpeningTipNote(this.tip);

  final OpeningTip tip;

  @override
  CoachTone get tone => CoachTone.tip;
}

/// The engine's verdict on the learner's last move.
class MoveQualityNote extends CoachNote {
  const MoveQualityNote(this.quality, {this.betterSan});

  final MoveQuality quality;

  /// A better alternative, for inaccuracies and worse.
  final String? betterSan;

  @override
  CoachTone get tone => switch (quality) {
    MoveQuality.best || MoveQuality.good => CoachTone.praise,
    MoveQuality.inaccuracy => CoachTone.tip,
    MoveQuality.mistake => CoachTone.warning,
    MoveQuality.blunder => CoachTone.danger,
  };
}

/// The explanation attached to a hint.
class HintNote extends CoachNote {
  const HintNote(this.san, this.reason, {this.mateIn});

  final String san;
  final HintReason reason;
  final int? mateIn;

  @override
  CoachTone get tone => CoachTone.tip;
}
