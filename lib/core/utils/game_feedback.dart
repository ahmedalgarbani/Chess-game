import 'package:flutter/services.dart';

import '../../features/settings/domain/app_settings.dart';

/// Haptic and sound feedback that respects the user's settings.
abstract final class GameFeedback {
  static void tap(AppSettings settings) {
    if (settings.haptics) HapticFeedback.selectionClick();
  }

  static void move(
    AppSettings settings, {
    bool capture = false,
    bool check = false,
  }) {
    if (settings.haptics) {
      if (check) {
        HapticFeedback.heavyImpact();
      } else if (capture) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
    if (settings.sounds) SystemSound.play(SystemSoundType.click);
  }

  static void alert(AppSettings settings) {
    if (settings.haptics) HapticFeedback.vibrate();
  }
}
