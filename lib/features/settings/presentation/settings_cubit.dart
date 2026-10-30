import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

/// Holds the current [AppSettings] and persists every change.
class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

  void update(AppSettings Function(AppSettings current) change) {
    final next = change(state);
    emit(next);
    _repository.save(next);
  }

  void completeOnboarding({
    required ExperienceLevel level,
    required String playerName,
  }) {
    update(
      (current) =>
          current.withExperience(level).copyWith(playerName: playerName),
    );
  }

  void setExperience(ExperienceLevel level) =>
      update((current) => current.withExperience(level));
}
