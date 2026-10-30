import '../../../engine/chess_ai.dart';

/// One of the ten computer opponents, from a random-ish beginner to a
/// full-strength engine.
class AiLevel {
  const AiLevel({
    required this.number,
    required this.skill,
    required this.approxRating,
  });

  /// 1 (easiest) to 10 (strongest).
  final int number;
  final EngineSkill skill;

  /// Rough playing strength, shown to the player.
  final int approxRating;

  static const all = <AiLevel>[
    AiLevel(
      number: 1,
      approxRating: 250,
      skill: EngineSkill(
        depth: 1,
        noise: 260,
        blunderChance: 0.3,
        quiescence: false,
      ),
    ),
    AiLevel(
      number: 2,
      approxRating: 450,
      skill: EngineSkill(
        depth: 1,
        noise: 160,
        blunderChance: 0.18,
        quiescence: false,
      ),
    ),
    AiLevel(
      number: 3,
      approxRating: 650,
      skill: EngineSkill(depth: 2, noise: 110, blunderChance: 0.1),
    ),
    AiLevel(
      number: 4,
      approxRating: 850,
      skill: EngineSkill(depth: 2, noise: 60, blunderChance: 0.06),
    ),
    AiLevel(
      number: 5,
      approxRating: 1050,
      skill: EngineSkill(depth: 3, noise: 40, blunderChance: 0.03),
    ),
    AiLevel(
      number: 6,
      approxRating: 1250,
      skill: EngineSkill(depth: 3, noise: 18, blunderChance: 0.01),
    ),
    AiLevel(
      number: 7,
      approxRating: 1450,
      skill: EngineSkill(depth: 4, timeLimitMs: 900),
    ),
    AiLevel(
      number: 8,
      approxRating: 1650,
      skill: EngineSkill(depth: 6, timeLimitMs: 1500),
    ),
    AiLevel(
      number: 9,
      approxRating: 1850,
      skill: EngineSkill(depth: 8, timeLimitMs: 2500),
    ),
    AiLevel(
      number: 10,
      approxRating: 2100,
      skill: EngineSkill(depth: 14, timeLimitMs: 4000),
    ),
  ];

  static AiLevel byNumber(int number) => all[(number - 1).clamp(0, 9)];
}
