import 'package:flutter/material.dart';

import '../../engine/chess_engine.dart';
import '../chess_ui/piece_painter.dart';
import '../theme/app_colors.dart';
import '../theme/board_theme.dart';

/// A gold coin counter.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.compact = false});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 20),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.goldLight,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small embossed coin.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.goldGradient,
        border: Border.all(color: AppColors.goldDeep, width: size * 0.08),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.star_rounded,
        size: size * 0.62,
        color: const Color(0xFF8A5E12),
      ),
    );
  }
}

/// A row of up to three stars.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.size = 18,
    this.total = 3,
  });

  final int stars;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? AppColors.gold : AppColors.textMuted,
          ),
      ],
    );
  }
}

/// A round medallion showing a chess piece, used for avatars and levels.
class PieceMedallion extends StatelessWidget {
  const PieceMedallion({
    super.key,
    required this.piece,
    this.size = 56,
    this.locked = false,
    this.glow = false,
  });

  final Piece piece;
  final double size;
  final bool locked;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: locked
            ? const LinearGradient(
                colors: [Color(0xFF2A3157), Color(0xFF1A1F3D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const RadialGradient(
                colors: [Color(0xFF34407A), Color(0xFF151A3A)],
                center: Alignment(-0.3, -0.4),
              ),
        border: Border.all(
          color: locked
              ? AppColors.textMuted.withValues(alpha: 0.4)
              : AppColors.gold,
          width: size * 0.045,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.45),
              blurRadius: size * 0.4,
              spreadRadius: size * 0.02,
            ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.14),
      child: locked
          ? Icon(
              Icons.lock_rounded,
              color: AppColors.textMuted,
              size: size * 0.42,
            )
          : PieceView(piece: piece, style: PieceStyle.royal, shadow: false),
    );
  }
}

/// A slim gold progress bar.
class GoldProgressBar extends StatelessWidget {
  const GoldProgressBar({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surfaceHigh),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: value.clamp(0, 1),
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.goldGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small section title with a gold accent.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
