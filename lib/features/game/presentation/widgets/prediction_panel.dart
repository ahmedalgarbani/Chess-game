import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../engine/chess_ai.dart';
import '../../../../engine/chess_engine.dart';

/// Human-readable evaluation, e.g. "White is better +1.2".
String evaluationText(AppStrings s, PositionAnalysis analysis) {
  final mate = analysis.mateIn;
  if (mate != null) {
    return s.evaluationMate(
      mate > 0 ? PieceColor.white : PieceColor.black,
      mate.abs(),
    );
  }
  final score = analysis.scoreWhite;
  if (score.abs() < 35) return s.evaluationEqual;
  return s.evaluationAdvantage(
    score > 0 ? PieceColor.white : PieceColor.black,
    formatPawns(score.abs()),
  );
}

/// Winning chances for white between 0 and 1.
double whiteWinShare(PositionAnalysis analysis) {
  final mate = analysis.mateIn;
  if (mate != null) return mate > 0 ? 1 : 0;
  return 1 / (1 + math.pow(10, -analysis.scoreWhite / 400));
}

/// A horizontal bar showing who is winning. While a new analysis is
/// running it keeps showing the previous evaluation instead of jumping back
/// to equal.
class EvaluationBar extends StatefulWidget {
  const EvaluationBar({super.key, required this.analysis});

  final PositionAnalysis? analysis;

  @override
  State<EvaluationBar> createState() => _EvaluationBarState();
}

class _EvaluationBarState extends State<EvaluationBar> {
  double _share = 0.5;

  @override
  Widget build(BuildContext context) {
    final current = widget.analysis;
    if (current != null) _share = whiteWinShare(current);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF0E1230)),
              TweenAnimationBuilder<double>(
                tween: Tween(end: _share),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFE9DFC8)],
                      ),
                    ),
                  ),
                ),
              ),
              Center(child: Container(width: 2, color: AppColors.gold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Evaluation, expected line and threat, shown when predictions are on.
class PredictionPanel extends StatelessWidget {
  const PredictionPanel({
    super.key,
    required this.analysis,
    required this.predictedLine,
    required this.threatSan,
  });

  final PositionAnalysis? analysis;
  final List<String> predictedLine;
  final String? threatSan;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final current = analysis;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sapphire.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sapphire.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.sapphire,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current == null ? s.analyzing : evaluationText(s, current),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (predictedLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(s.predictedLine, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (index, san) in predictedLine.indexed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sapphire.withValues(
                          alpha: index.isEven ? 0.28 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${index + 1}. $san',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (threatSan != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.gpp_maybe_rounded,
                  color: AppColors.ruby,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  s.threat(threatSan!),
                  style: const TextStyle(
                    color: AppColors.ruby,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
