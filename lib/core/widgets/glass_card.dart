import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A translucent rounded card with a thin gold edge.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.onTap,
    this.borderColor,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? AppColors.outline),
    );
    return Material(
      color: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(
          shape: shape,
          gradient: gradient ?? AppColors.cardGradient,
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.gold.withValues(alpha: 0.12),
          highlightColor: AppColors.gold.withValues(alpha: 0.06),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
