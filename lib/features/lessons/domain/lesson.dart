import '../../../engine/chess_engine.dart';

/// A piece of lesson text in both supported languages.
class LocalizedText {
  const LocalizedText(this.ar, this.en);

  final String ar;
  final String en;

  String resolve({required bool arabic}) => arabic ? ar : en;
}

/// What the learner must do to finish a lesson step.
sealed class LessonGoal {
  const LessonGoal();
}

/// Move the learner's piece(s) onto every star. The learner keeps the move.
class CollectStarsGoal extends LessonGoal {
  const CollectStarsGoal(this.stars);

  /// Square names such as `e4`.
  final List<String> stars;
}

/// Capture every enemy piece except the king. The learner keeps the move.
class CaptureAllGoal extends LessonGoal {
  const CaptureAllGoal();
}

/// Deliver checkmate in one move.
class CheckmateGoal extends LessonGoal {
  const CheckmateGoal();
}

/// Play a special move (castling, en passant or promotion).
class SpecialMoveGoal extends LessonGoal {
  const SpecialMoveGoal(this.kinds, {this.promotion = false});

  final Set<MoveKind> kinds;

  /// Whether any promotion satisfies the goal.
  final bool promotion;
}

/// Play one of the listed moves (UCI).
class PlayMoveGoal extends LessonGoal {
  const PlayMoveGoal(this.moves);

  final List<String> moves;
}

/// One screen of a lesson: an explanation, a position and an optional task.
class LessonStep {
  const LessonStep({
    required this.text,
    required this.fen,
    this.goal,
    this.highlights = const [],
  });

  final LocalizedText text;
  final String fen;

  /// Null for explanation-only steps.
  final LessonGoal? goal;

  /// Square names to highlight.
  final List<String> highlights;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.steps,
  });

  final String id;
  final PieceType icon;
  final LocalizedText title;
  final LocalizedText summary;
  final List<LessonStep> steps;
}
