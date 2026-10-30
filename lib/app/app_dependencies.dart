import 'package:shared_preferences/shared_preferences.dart';

import '../features/game/data/isolate_chess_ai_service.dart';
import '../features/game/domain/chess_ai_service.dart';
import '../features/lan/data/lan_service_factory.dart';
import '../features/lan/domain/lan_service.dart';
import '../features/progress/data/prefs_progress_repository.dart';
import '../features/progress/domain/progress_repository.dart';
import '../features/settings/data/prefs_settings_repository.dart';
import '../features/settings/domain/settings_repository.dart';

/// Composition root: creates the concrete implementations used by the app.
class AppDependencies {
  const AppDependencies({
    required this.settingsRepository,
    required this.progressRepository,
    required this.aiService,
    required this.lanService,
  });

  static Future<AppDependencies> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppDependencies(
      settingsRepository: PrefsSettingsRepository(prefs),
      progressRepository: PrefsProgressRepository(prefs),
      aiService: IsolateChessAiService(),
      lanService: createLanService(),
    );
  }

  final SettingsRepository settingsRepository;
  final ProgressRepository progressRepository;
  final ChessAiService aiService;
  final LanService lanService;
}
