import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/chess_ui/piece_painter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../core/widgets/royal_button.dart';
import '../../../engine/chess_engine.dart';
import '../../home/presentation/home_page.dart';
import '../../lessons/presentation/lessons_page.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_cubit.dart';

/// First launch: name, language and experience level.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  ExperienceLevel _level = ExperienceLevel.beginner;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<SettingsCubit>().completeOnboarding(
      level: _level,
      playerName: _nameController.text.trim(),
    );
    final navigator = Navigator.of(context);
    navigator.pushReplacement(AppRoutes.fade(const HomePage()));
    if (_level == ExperienceLevel.beginner) {
      navigator.push(AppRoutes.fade(const LessonsPage(welcome: true)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final language = context.watch<SettingsCubit>().state.language;
    return Scaffold(
      body: RoyalBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _LanguageToggle(language: language),
              ),
              const SizedBox(height: 8),
              const _Logo(),
              const SizedBox(height: 10),
              Text(
                s.welcomeTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                s.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: s.yourName,
                  hintText: s.namePlaceholder,
                  counterText: '',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                s.experienceQuestion,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final level in ExperienceLevel.values) ...[
                _ExperienceCard(
                  level: level,
                  selected: level == _level,
                  onTap: () => setState(() => _level = level),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              RoyalButton(
                label: s.letsGo,
                icon: Icons.arrow_forward_rounded,
                onPressed: _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [palette.surfaceHigh, palette.backgroundBottom],
            ),
            border: Border.all(color: palette.accent, width: 3),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.35),
                blurRadius: 40,
              ),
            ],
          ),
          child: const PieceView(
            piece: Piece.whiteKnight,
            style: PieceStyle.royal,
            shadow: false,
          ),
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (rect) => palette.accentGradient.createShader(rect),
          child: Text(
            context.s.isArabic ? 'رُقعة' : 'Ruqa',
            style: const TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 64,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          context.s.appTagline,
          style: TextStyle(
            color: palette.accentLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final next = language == AppLanguage.arabic
        ? AppLanguage.english
        : AppLanguage.arabic;
    return TextButton.icon(
      onPressed: () => context.read<SettingsCubit>().update(
        (s) => s.copyWith(language: next),
      ),
      icon: const Icon(Icons.translate_rounded, size: 18),
      label: Text(next == AppLanguage.english ? 'English' : 'العربية'),
      style: TextButton.styleFrom(foregroundColor: palette.accentLight),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ExperienceLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.s;
    final piece = switch (level) {
      ExperienceLevel.beginner => Piece.whitePawn,
      ExperienceLevel.intermediate => Piece.whiteKnight,
      ExperienceLevel.advanced => Piece.whiteKing,
    };
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: selected ? 1 : 0.98,
      child: GlassCard(
        onTap: onTap,
        borderColor: selected ? palette.accent : null,
        gradient: selected
            ? LinearGradient(
                colors: [
                  palette.accent.withValues(alpha: 0.22),
                  palette.accent.withValues(alpha: 0.05),
                ],
              )
            : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 52,
              child: PieceView(piece: piece, style: PieceStyle.royal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.experienceName(level),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.experienceDescription(level),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(selected),
                color: selected ? palette.accent : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
