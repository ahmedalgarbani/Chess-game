import 'package:flutter/material.dart';

/// Semantic colours shared by every app theme. The brand colours
/// (backgrounds, surfaces and the accent) come from the active
/// `AppPalette`, see `context.palette`.
abstract final class AppColors {
  static const Color surfaceGlass = Color(0x1AFFFFFF);

  static const Color emerald = Color(0xFF2EC4A5);
  static const Color ruby = Color(0xFFE5566E);
  static const Color sapphire = Color(0xFF6C9BFF);
  static const Color amethyst = Color(0xFFA978F2);
  static const Color amber = Color(0xFFF2B53D);

  static const Color textPrimary = Color(0xFFF6F1E4);
  static const Color textSecondary = Color(0xFFB9BDDA);
  static const Color textMuted = Color(0xFF7E84AA);

  static const Color divider = Color(0x1FFFFFFF);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
  );
}
