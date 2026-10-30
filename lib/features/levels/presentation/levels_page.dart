import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/royal_background.dart';
import '../../game/domain/ai_level.dart';
import '../../game/presentation/pages/game_setup_sheet.dart';
import '../../progress/domain/player_progress.dart';
import '../../progress/presentation/progress_cubit.dart';

/// The computer levels as a winding journey from level 1 (bottom) to the
/// legend at the top.
class LevelsPage extends StatelessWidget {
  const LevelsPage({super.key});

  static const double _rowHeight = 150;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final progress = context.watch<ProgressCubit>().state;
    final levels = AiLevel.all.reversed.toList();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(s.levelsTitle)),
      body: RoyalBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = levels.length * _rowHeight + 40;
              Offset centerOf(int index) {
                final number = levels[index].number;
                final x = width / 2 + math.sin(number * 1.15) * width * 0.26;
                return Offset(x, 40 + index * _rowHeight + _rowHeight / 2);
              }

              return SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Text(
                        s.levelsSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      height: height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PathPainter(
                                [
                                  for (var i = 0; i < levels.length; i++)
                                    centerOf(i),
                                ],
                                unlockedFromBottom:
                                    progress.highestUnlockedLevel,
                                color: palette.accent,
                              ),
                            ),
                          ),
                          for (var i = 0; i < levels.length; i++)
                            Positioned(
                              left: centerOf(i).dx - 70,
                              top: centerOf(i).dy - 62,
                              width: 140,
                              child: _LevelNode(
                                level: levels[i],
                                progress: progress,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatefulWidget {
  const _LevelNode({required this.level, required this.progress});

  final AiLevel level;
  final PlayerProgress progress;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _isCurrent =>
      widget.level.number == widget.progress.highestUnlockedLevel &&
      !widget.progress.levelStars.containsKey(widget.level.number);

  @override
  void initState() {
    super.initState();
    if (_isCurrent) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final number = widget.level.number;
    final unlocked = widget.progress.isLevelUnlocked(number);
    final stars = widget.progress.levelStars[number] ?? 0;
    return GestureDetector(
      onTap: () {
        if (unlocked) {
          showComputerGameSheet(context, level: widget.level, ladder: true);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.levelLocked)));
        }
      },
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(
              scale: _isCurrent ? 1 + _pulse.value * 0.06 : 1,
              child: child,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                PieceMedallion(
                  piece: levelPiece(number),
                  size: number == 10 ? 86 : 74,
                  locked: !unlocked,
                  glow: _isCurrent || number == 10 && unlocked,
                ),
                Positioned(
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: unlocked ? palette.accentGradient : null,
                      color: unlocked ? null : palette.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: palette.background, width: 2),
                    ),
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: unlocked
                            ? palette.onAccent
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          StarRow(stars: stars, size: 18),
          Text(
            s.aiLevelName(number),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dotted golden trail connecting the level nodes.
class _PathPainter extends CustomPainter {
  _PathPainter(
    this.points, {
    required this.unlockedFromBottom,
    required this.color,
  });

  /// Node centres from the top (level 10) to the bottom (level 1).
  final List<Offset> points;
  final int unlockedFromBottom;

  /// Colour of the trail between unlocked levels.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    for (var i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      // Segment between level (n) at the top and (n-1) below it.
      final upperLevel = points.length - i;
      final reached = upperLevel <= unlockedFromBottom;
      final paint = Paint()
        ..color = reached
            ? color.withValues(alpha: 0.85)
            : AppColors.textMuted.withValues(alpha: 0.35)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      final control = Offset(
        (from.dx + to.dx) / 2 + (from.dx - to.dx) * 0.6,
        (from.dy + to.dy) / 2,
      );
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 16) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) {
            canvas.drawCircle(tangent.position, 3, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.points != points ||
      old.unlockedFromBottom != unlockedFromBottom ||
      old.color != color;
}
