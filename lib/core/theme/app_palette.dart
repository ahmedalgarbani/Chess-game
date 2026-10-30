import 'package:flutter/material.dart';

/// The brand colours of an app theme: backgrounds, surfaces and the accent
/// used for buttons, highlights and frames. Themes are unlockable rewards;
/// semantic colours (success, danger, text) stay in `AppColors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.price,
    required this.backgroundTop,
    required this.background,
    required this.backgroundBottom,
    required this.surface,
    required this.surfaceHigh,
    required this.accent,
    required this.accentLight,
    required this.accentDeep,
    required this.onAccent,
  });

  final String id;

  /// Cost in coins; 0 means owned from the start.
  final int price;

  final Color backgroundTop;
  final Color background;
  final Color backgroundBottom;
  final Color surface;
  final Color surfaceHigh;
  final Color accent;
  final Color accentLight;
  final Color accentDeep;

  /// Text and icons drawn on top of the accent.
  final Color onAccent;

  Color get outline => accent.withValues(alpha: 0.2);

  /// Colour of the geometric background pattern.
  Color get pattern => accent.withValues(alpha: 0.08);

  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDeep],
    stops: const [0, 0.45, 1],
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, background, backgroundBottom],
    stops: const [0, 0.55, 1],
  );

  /// Royal night: midnight blue and gold.
  static const royal = AppPalette(
    id: 'royal',
    price: 0,
    backgroundTop: Color(0xFF1C1F4D),
    background: Color(0xFF0B1026),
    backgroundBottom: Color(0xFF070A1A),
    surface: Color(0xFF171D42),
    surfaceHigh: Color(0xFF222A5A),
    accent: Color(0xFFE9B44C),
    accentLight: Color(0xFFF8DE97),
    accentDeep: Color(0xFFB07D22),
    onAccent: Color(0xFF2A1C02),
  );

  static const all = <AppPalette>[
    royal,
    AppPalette(
      id: 'emerald',
      price: 300,
      backgroundTop: Color(0xFF0F3B33),
      background: Color(0xFF062621),
      backgroundBottom: Color(0xFF031612),
      surface: Color(0xFF0C3029),
      surfaceHigh: Color(0xFF13423A),
      accent: Color(0xFF3DD6A3),
      accentLight: Color(0xFFB4F3DC),
      accentDeep: Color(0xFF1C9A72),
      onAccent: Color(0xFF04241B),
    ),
    AppPalette(
      id: 'desert',
      price: 350,
      backgroundTop: Color(0xFF4A2416),
      background: Color(0xFF24110B),
      backgroundBottom: Color(0xFF140906),
      surface: Color(0xFF301811),
      surfaceHigh: Color(0xFF43231A),
      accent: Color(0xFFF2A541),
      accentLight: Color(0xFFFFD79A),
      accentDeep: Color(0xFFC0711C),
      onAccent: Color(0xFF2B1503),
    ),
    AppPalette(
      id: 'rose',
      price: 400,
      backgroundTop: Color(0xFF4A1840),
      background: Color(0xFF22091F),
      backgroundBottom: Color(0xFF130512),
      surface: Color(0xFF2F0F2A),
      surfaceHigh: Color(0xFF43173C),
      accent: Color(0xFFF48FB1),
      accentLight: Color(0xFFFFD1E1),
      accentDeep: Color(0xFFC2507B),
      onAccent: Color(0xFF3A0A20),
    ),
    AppPalette(
      id: 'ocean',
      price: 450,
      backgroundTop: Color(0xFF0B3A55),
      background: Color(0xFF05192A),
      backgroundBottom: Color(0xFF020D17),
      surface: Color(0xFF0A2538),
      surfaceHigh: Color(0xFF10344D),
      accent: Color(0xFF5CD2F2),
      accentLight: Color(0xFFC2F1FF),
      accentDeep: Color(0xFF1F92B8),
      onAccent: Color(0xFF03202B),
    ),
    AppPalette(
      id: 'obsidian',
      price: 500,
      backgroundTop: Color(0xFF2A2C33),
      background: Color(0xFF121317),
      backgroundBottom: Color(0xFF08090B),
      surface: Color(0xFF1B1D22),
      surfaceHigh: Color(0xFF272A31),
      accent: Color(0xFFD3DAE4),
      accentLight: Color(0xFFFFFFFF),
      accentDeep: Color(0xFF8E99A8),
      onAccent: Color(0xFF15181D),
    ),
  ];

  static AppPalette byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => royal);

  @override
  AppPalette copyWith({Color? accent}) => AppPalette(
    id: id,
    price: price,
    backgroundTop: backgroundTop,
    background: background,
    backgroundBottom: backgroundBottom,
    surface: surface,
    surfaceHigh: surfaceHigh,
    accent: accent ?? this.accent,
    accentLight: accentLight,
    accentDeep: accentDeep,
    onAccent: onAccent,
  );

  /// Blends two palettes so theme changes animate smoothly.
  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      price: t < 0.5 ? price : other.price,
      backgroundTop: mix(backgroundTop, other.backgroundTop),
      background: mix(background, other.background),
      backgroundBottom: mix(backgroundBottom, other.backgroundBottom),
      surface: mix(surface, other.surface),
      surfaceHigh: mix(surfaceHigh, other.surfaceHigh),
      accent: mix(accent, other.accent),
      accentLight: mix(accentLight, other.accentLight),
      accentDeep: mix(accentDeep, other.accentDeep),
      onAccent: mix(onAccent, other.onAccent),
    );
  }
}

extension AppPaletteX on BuildContext {
  /// The active app theme's brand colours.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.royal;
}
