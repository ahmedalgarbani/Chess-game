import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/achievement.dart';
import '../domain/game_summary.dart';
import '../domain/player_progress.dart';
import '../domain/progress_repository.dart';
import '../domain/reward_rules.dart';
import '../domain/shop_items.dart';

/// Owns the player's progress and applies the reward rules.
class ProgressCubit extends Cubit<PlayerProgress> {
  ProgressCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(_repository.load());

  final ProgressRepository _repository;
  final DateTime Function() _clock;

  GameRewards recordGame(GameSummary summary) {
    final (updated, rewards) = RewardRules.applyGame(state, summary);
    _commit(updated);
    return rewards;
  }

  /// Returns the rewards, or null if the lesson was completed before.
  GameRewards? completeLesson(String lessonId, {required int totalLessons}) {
    final result = RewardRules.applyLesson(
      state,
      lessonId,
      totalLessons: totalLessons,
    );
    if (result == null) return null;
    _commit(result.$1);
    return result.$2;
  }

  bool get canClaimDaily => state.canClaimDaily(_clock());

  /// Returns the coins received, or null if already claimed today.
  int? claimDaily() {
    final result = RewardRules.claimDaily(state, _clock());
    if (result == null) return null;
    _commit(result.$1);
    return result.$2;
  }

  /// Buys a cosmetic; returns the achievements earned, or null when the
  /// item is already owned or unaffordable.
  List<Achievement>? buy(CosmeticKind kind, String id, int price) {
    final result = RewardRules.purchase(state, kind, id, price);
    if (result == null) return null;
    _commit(result.$1);
    return result.$2;
  }

  /// Buys a boost; returns the achievements earned, or null when
  /// unaffordable.
  List<Achievement>? buyBoost(Boost boost) {
    final result = RewardRules.purchaseBoost(state, boost);
    if (result == null) return null;
    _commit(result.$1);
    return result.$2;
  }

  /// Uses one purchased hint. Returns false when none is left.
  bool spendHintToken() {
    final updated = RewardRules.spendHintToken(state);
    if (updated == null) return false;
    _commit(updated);
    return true;
  }

  /// Records a solved puzzle; null when nothing new was earned.
  GameRewards? solvePuzzle(
    String puzzleId, {
    required int coins,
    required int xp,
    required bool isDaily,
    required int totalPuzzles,
  }) {
    final result = RewardRules.applyPuzzle(
      state,
      puzzleId,
      coins: coins,
      xp: xp,
      isDaily: isDaily,
      totalPuzzles: totalPuzzles,
      now: _clock(),
    );
    if (result == null) return null;
    _commit(result.$1);
    return result.$2;
  }

  Future<void> reset() async {
    await _repository.clear();
    emit(const PlayerProgress());
  }

  void _commit(PlayerProgress progress) {
    emit(progress);
    _repository.save(progress);
  }
}
