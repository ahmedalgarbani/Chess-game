import 'package:flutter/material.dart';

/// Colours of the chess board. Themes are unlockable rewards.
class BoardTheme {
  const BoardTheme({
    required this.id,
    required this.light,
    required this.dark,
    required this.price,
    this.coordinateOnLight,
    this.coordinateOnDark,
  });

  final String id;
  final Color light;
  final Color dark;

  /// Cost in coins; 0 means owned from the start.
  final int price;

  final Color? coordinateOnLight;
  final Color? coordinateOnDark;

  Color get coordinateLight => coordinateOnLight ?? dark;
  Color get coordinateDark => coordinateOnDark ?? light;

  static const royal = BoardTheme(
    id: 'royal',
    light: Color(0xFFF0DCB4),
    dark: Color(0xFFB0794B),
    price: 0,
  );

  static const midnight = BoardTheme(
    id: 'midnight',
    light: Color(0xFFDDE4F3),
    dark: Color(0xFF5468A0),
    price: 0,
  );

  static const all = <BoardTheme>[
    royal,
    midnight,
    BoardTheme(
      id: 'emerald',
      light: Color(0xFFEEEED2),
      dark: Color(0xFF6E9A55),
      price: 150,
    ),
    BoardTheme(
      id: 'desert',
      light: Color(0xFFF7E8C7),
      dark: Color(0xFFCB9A58),
      price: 200,
    ),
    BoardTheme(
      id: 'coral',
      light: Color(0xFFFCE4D8),
      dark: Color(0xFFD27766),
      price: 250,
    ),
    BoardTheme(
      id: 'ocean',
      light: Color(0xFFD8EEF4),
      dark: Color(0xFF3F88A6),
      price: 300,
    ),
    BoardTheme(
      id: 'marble',
      light: Color(0xFFF1F1EF),
      dark: Color(0xFF8E95A2),
      price: 400,
    ),
    BoardTheme(
      id: 'golden',
      light: Color(0xFFFBEBBE),
      dark: Color(0xFFC79332),
      price: 600,
    ),
    BoardTheme(
      id: 'amethyst',
      light: Color(0xFFEDE3F7),
      dark: Color(0xFF8B6BB8),
      price: 300,
    ),
    BoardTheme(
      id: 'rose',
      light: Color(0xFFFBE7EE),
      dark: Color(0xFFC77B97),
      price: 300,
    ),
    BoardTheme(
      id: 'forest',
      light: Color(0xFFE7EFD9),
      dark: Color(0xFF4E7A4B),
      price: 350,
    ),
    BoardTheme(
      id: 'obsidian',
      light: Color(0xFFB9BEC7),
      dark: Color(0xFF3C4048),
      price: 500,
      coordinateOnLight: Color(0xFF3C4048),
      coordinateOnDark: Color(0xFFDDE1E7),
    ),
  ];

  static BoardTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => royal);
}

/// Colours used to paint the pieces. Styles are unlockable rewards.
class PieceStyle {
  const PieceStyle({
    required this.id,
    required this.whiteFill,
    required this.whiteStroke,
    required this.blackFill,
    required this.blackStroke,
    required this.price,
  });

  final String id;

  /// Top-to-bottom gradient of the white pieces.
  final List<Color> whiteFill;
  final Color whiteStroke;

  /// Top-to-bottom gradient of the black pieces.
  final List<Color> blackFill;
  final Color blackStroke;

  final int price;

  static const royal = PieceStyle(
    id: 'royal',
    whiteFill: [Color(0xFFFFFFFF), Color(0xFFF3E9D6), Color(0xFFD9C7A3)],
    whiteStroke: Color(0xFF5B4114),
    blackFill: [Color(0xFF39457A), Color(0xFF1C2350), Color(0xFF0D1130)],
    blackStroke: Color(0xFFE9B44C),
    price: 0,
  );

  static const all = <PieceStyle>[
    royal,
    PieceStyle(
      id: 'classic',
      whiteFill: [Color(0xFFFFFFFF), Color(0xFFF1EDE4), Color(0xFFD4CCBC)],
      whiteStroke: Color(0xFF26231E),
      blackFill: [Color(0xFF55565C), Color(0xFF2A2B30), Color(0xFF111114)],
      blackStroke: Color(0xFF050506),
      price: 0,
    ),
    PieceStyle(
      id: 'emeraldRuby',
      whiteFill: [Color(0xFFEFFFF9), Color(0xFFB6EBD9), Color(0xFF6CC6A8)],
      whiteStroke: Color(0xFF14523F),
      blackFill: [Color(0xFFE0566F), Color(0xFF9E1F3B), Color(0xFF5A0B1F)],
      blackStroke: Color(0xFF2B0510),
      price: 250,
    ),
    PieceStyle(
      id: 'sapphireGold',
      whiteFill: [Color(0xFFFFF6DC), Color(0xFFF2CF77), Color(0xFFC9932F)],
      whiteStroke: Color(0xFF5E3E07),
      blackFill: [Color(0xFF6C8CFF), Color(0xFF3651C9), Color(0xFF17266E)],
      blackStroke: Color(0xFF070F3A),
      price: 350,
    ),
    PieceStyle(
      id: 'wood',
      whiteFill: [Color(0xFFFFF1D6), Color(0xFFF0CF96), Color(0xFFD3A35E)],
      whiteStroke: Color(0xFF5B3A12),
      blackFill: [Color(0xFF8A5A33), Color(0xFF5E3A1E), Color(0xFF3A2210)],
      blackStroke: Color(0xFF1E1006),
      price: 300,
    ),
    PieceStyle(
      id: 'roseOnyx',
      whiteFill: [Color(0xFFFFF0EC), Color(0xFFF4C1B4), Color(0xFFD98E7E)],
      whiteStroke: Color(0xFF6B2F25),
      blackFill: [Color(0xFF3B3B40), Color(0xFF1F1F23), Color(0xFF0B0B0D)],
      blackStroke: Color(0xFFE8A898),
      price: 400,
    ),
    PieceStyle(
      id: 'glacierLava',
      whiteFill: [Color(0xFFFFFFFF), Color(0xFFD5F1FF), Color(0xFF8CCFF0)],
      whiteStroke: Color(0xFF1C5A7A),
      blackFill: [Color(0xFFFFB347), Color(0xFFE5501B), Color(0xFF8E1C0B)],
      blackStroke: Color(0xFF3A0A02),
      price: 450,
    ),
    PieceStyle(
      id: 'marble',
      whiteFill: [Color(0xFFFFFFFF), Color(0xFFE6E9EE), Color(0xFFB9C0CB)],
      whiteStroke: Color(0xFF3D434D),
      blackFill: [Color(0xFF6E7684), Color(0xFF3A404B), Color(0xFF1B1E24)],
      blackStroke: Color(0xFFD7DCE4),
      price: 450,
    ),
  ];

  static PieceStyle byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => royal);
}
