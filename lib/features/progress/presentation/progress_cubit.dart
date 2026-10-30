import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/game_summary.dart';
import '../domain/player_progress.dart';
import '../domain/progress_repository.dart';
import '../domain/reward_rules.dart';

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

  bool buyBoardTheme(String id, int price) {
    if (state.ownedBoardThemes.contains(id) || state.coins < price) {
      return false;
    }
    _commit(
      state.copyWith(
        coins: state.coins - price,
        ownedBoardThemes: {...state.ownedBoardThemes, id},
      ),
    );
    return true;
  }

  bool buyPieceStyle(String id, int price) {
    if (state.ownedPieceStyles.contains(id) || state.coins < price) {
      return false;
    }
    _commit(
      state.copyWith(
        coins: state.coins - price,
        ownedPieceStyles: {...state.ownedPieceStyles, id},
      ),
    );
    return true;
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
