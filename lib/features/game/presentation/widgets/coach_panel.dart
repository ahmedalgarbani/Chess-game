import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/coach/coach_note.dart';

/// Colour and icon for each coach tone.
extension CoachToneStyle on CoachTone {
  Color get color => switch (this) {
    CoachTone.info => AppColors.sapphire,
    CoachTone.tip => AppColors.amethyst,
    CoachTone.praise => AppColors.emerald,
    CoachTone.warning => AppColors.amber,
    CoachTone.danger => AppColors.ruby,
  };

  IconData get icon => switch (this) {
    CoachTone.info => Icons.lightbulb_outline_rounded,
    CoachTone.tip => Icons.tips_and_updates_rounded,
    CoachTone.praise => Icons.emoji_events_rounded,
    CoachTone.warning => Icons.warning_amber_rounded,
    CoachTone.danger => Icons.report_rounded,
  };
}

/// The coach's latest explanations, newest first.
class CoachPanel extends StatelessWidget {
  const CoachPanel({super.key, required this.notes});

  final List<CoachNote> notes;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _CoachBubble(
          key: ObjectKey(note),
          note: note,
          text: s.coachNote(note),
          highlighted: index == 0,
        );
      },
    );
  }
}

class _CoachBubble extends StatefulWidget {
  const _CoachBubble({
    super.key,
    required this.note,
    required this.text,
    required this.highlighted,
  });

  final CoachNote note;
  final String text;
  final bool highlighted;

  @override
  State<_CoachBubble> createState() => _CoachBubbleState();
}

class _CoachBubbleState extends State<_CoachBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.note.tone;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(curved),
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: widget.highlighted ? 1 : 0.72,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tone.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tone.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(tone.icon, color: tone.color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
