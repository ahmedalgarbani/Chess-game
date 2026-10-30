import 'app_settings.dart';

/// Persists [AppSettings].
abstract interface class SettingsRepository {
  AppSettings load();

  Future<void> save(AppSettings settings);
}
