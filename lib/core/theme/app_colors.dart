import 'package:flutter/material.dart';

/// The "royal night" palette: deep midnight blues with gold accents.
abstract final class AppColors {
  static const Color background = Color(0xFF0B1026);
  static const Color backgroundTop = Color(0xFF1C1F4D);
  static const Color surface = Color(0xFF171D42);
  static const Color surfaceHigh = Color(0xFF222A5A);
  static const Color surfaceGlass = Color(0x1AFFFFFF);

  static const Color gold = Color(0xFFE9B44C);
  static const Color goldLight = Color(0xFFF8DE97);
  static const Color goldDeep = Color(0xFFB07D22);

  static const Color emerald = Color(0xFF2EC4A5);
  static const Color ruby = Color(0xFFE5566E);
  static const Color sapphire = Color(0xFF6C9BFF);
  static const Color amethyst = Color(0xFFA978F2);

  static const Color textPrimary = Color(0xFFF6F1E4);
  static const Color textSecondary = Color(0xFFB9BDDA);
  static const Color textMuted = Color(0xFF7E84AA);

  static const Color outline = Color(0x33E9B44C);
  static const Color divider = Color(0x1FFFFFFF);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDeep],
    stops: [0, 0.45, 1],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, background, Color(0xFF070A1A)],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
  );
}
