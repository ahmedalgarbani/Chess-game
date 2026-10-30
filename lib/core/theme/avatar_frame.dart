import 'package:flutter/material.dart';

/// A decorative ring around the player's avatar medallion. Frames are
/// unlockable rewards.
class AvatarFrame {
  const AvatarFrame({required this.id, required this.price, this.colors});

  final String id;

  /// Cost in coins; 0 means owned from the start.
  final int price;

  /// Colours swept around the ring; null uses the app theme's accent.
  final List<Color>? colors;

  /// The ring's gradient, falling back to [accent] for the classic frame.
  Gradient gradient(Color accent) => SweepGradient(
    colors: colors ?? [accent, accent.withValues(alpha: 0.75), accent],
  );

  static const classic = AvatarFrame(id: 'classic', price: 0);

  static const all = <AvatarFrame>[
    classic,
    AvatarFrame(
      id: 'silver',
      price: 120,
      colors: [
        Color(0xFFF7F9FB),
        Color(0xFF9AA5B1),
        Color(0xFFE8EDF2),
        Color(0xFF8D97A3),
        Color(0xFFF7F9FB),
      ],
    ),
    AvatarFrame(
      id: 'emerald',
      price: 200,
      colors: [
        Color(0xFFB4F3DC),
        Color(0xFF1E9C74),
        Color(0xFF7EF2C8),
        Color(0xFF157A5B),
        Color(0xFFB4F3DC),
      ],
    ),
    AvatarFrame(
      id: 'ruby',
      price: 250,
      colors: [
        Color(0xFFFFC2CC),
        Color(0xFFB3263F),
        Color(0xFFFF8DA1),
        Color(0xFF8E1B30),
        Color(0xFFFFC2CC),
      ],
    ),
    AvatarFrame(
      id: 'sapphire',
      price: 250,
      colors: [
        Color(0xFFC9DCFF),
        Color(0xFF2F5BD3),
        Color(0xFF9CC0FF),
        Color(0xFF1D3E9E),
        Color(0xFFC9DCFF),
      ],
    ),
    AvatarFrame(
      id: 'flame',
      price: 450,
      colors: [
        Color(0xFFFFE66D),
        Color(0xFFFF9F1C),
        Color(0xFFE71D36),
        Color(0xFFFF9F1C),
        Color(0xFFFFE66D),
      ],
    ),
    AvatarFrame(
      id: 'rainbow',
      price: 600,
      colors: [
        Color(0xFFFF6B6B),
        Color(0xFFFFD93D),
        Color(0xFF6BCB77),
        Color(0xFF4D96FF),
        Color(0xFFC77DFF),
        Color(0xFFFF6B6B),
      ],
    ),
  ];

  static AvatarFrame byId(String id) =>
      all.firstWhere((f) => f.id == id, orElse: () => classic);
}
