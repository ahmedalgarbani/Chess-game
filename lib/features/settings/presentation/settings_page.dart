import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../history/presentation/history_cubit.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../domain/app_settings.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      extendBodyBehindAppBar: true,
      body: RoyalBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SectionTitle(s.languageLabel),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(
                      value: AppLanguage.arabic,
                      label: Text('العربية'),
                    ),
                    ButtonSegment(
                      value: AppLanguage.english,
                      label: Text('English'),
                    ),
                  ],
                  selected: {settings.language},
                  onSelectionChanged: (value) =>
                      cubit.update((s) => s.copyWith(language: value.first)),
                ),
              ),
              const SizedBox(height: 18),
              const AssistanceSettings(),
              const SizedBox(height: 18),
              SectionTitle(s.boardSection),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    SettingsSwitch(
                      title: s.showCoordinates,
                      icon: Icons.grid_on_rounded,
                      value: settings.showCoordinates,
                      onChanged: (v) =>
                          cubit.update((s) => s.copyWith(showCoordinates: v)),
                    ),
                    SettingsSwitch(
                      title: s.autoQueen,
                      icon: Icons.upgrade_rounded,
                      value: settings.autoQueen,
                      onChanged: (v) =>
                          cubit.update((s) => s.copyWith(autoQueen: v)),
                    ),
                    SettingsSwitch(
                      title: s.autoFlipSetting,
                      icon: Icons.screen_rotation_alt_rounded,
                      value: settings.autoFlipBoard,
                      onChanged: (v) =>
                          cubit.update((s) => s.copyWith(autoFlipBoard: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(s.feedbackSection),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    SettingsSwitch(
                      title: s.haptics,
                      icon: Icons.vibration_rounded,
                      value: settings.haptics,
                      onChanged: (v) =>
                          cubit.update((s) => s.copyWith(haptics: v)),
                    ),
                    SettingsSwitch(
                      title: s.sounds,
                      icon: Icons.volume_up_rounded,
                      value: settings.sounds,
                      onChanged: (v) =>
                          cubit.update((s) => s.copyWith(sounds: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(s.profileSection),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NameEditor(initial: settings.playerName),
                    const SizedBox(height: 14),
                    Text(
                      s.experience,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final level in ExperienceLevel.values)
                          ChoiceChip(
                            label: Text(s.experienceName(level)),
                            selected: settings.experience == level,
                            onSelected: (_) => cubit.setExperience(level),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _confirmReset(context),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(s.resetProgress),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ruby,
                  side: BorderSide(
                    color: AppColors.ruby.withValues(alpha: 0.5),
                  ),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.resetProgress),
        content: Text(s.resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.ruby),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.resetProgress),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProgressCubit>().reset();
    if (!context.mounted) return;
    await context.read<HistoryCubit>().clear();
    if (!context.mounted) return;
    // Purchased cosmetics are gone, so fall back to the free ones.
    context.read<SettingsCubit>().update((s) => s.withDefaultCosmetics());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.progressReset)));
  }
}

/// Learning mode, safeguards and predictions. Shared by the settings page
/// and the in-game quick settings sheet.
class AssistanceSettings extends StatelessWidget {
  const AssistanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(s.learningSection),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SettingsSwitch(
            title: s.learningMode,
            subtitle: s.learningModeDesc,
            icon: Icons.school_rounded,
            value: settings.learningMode,
            onChanged: (v) => cubit.update((s) => s.copyWith(learningMode: v)),
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(s.safeguardsSection),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SettingsSwitch(
                title: s.showLegalMoves,
                subtitle: s.showLegalMovesDesc,
                icon: Icons.blur_on_rounded,
                value: settings.showLegalMoves,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(showLegalMoves: v)),
              ),
              SettingsSwitch(
                title: s.highlightThreats,
                subtitle: s.highlightThreatsDesc,
                icon: Icons.crisis_alert_rounded,
                value: settings.highlightThreats,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(highlightThreats: v)),
              ),
              SettingsSwitch(
                title: s.blunderGuard,
                subtitle: s.blunderGuardDesc,
                icon: Icons.shield_rounded,
                value: settings.blunderGuard,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(blunderGuard: v)),
              ),
              SettingsSwitch(
                title: s.allowUndo,
                subtitle: s.allowUndoDesc,
                icon: Icons.undo_rounded,
                value: settings.allowUndo,
                onChanged: (v) => cubit.update((s) => s.copyWith(allowUndo: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionTitle(s.predictionsSection),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SettingsSwitch(
            title: s.showPredictions,
            subtitle: s.showPredictionsDesc,
            icon: Icons.auto_awesome_rounded,
            value: settings.showPredictions,
            onChanged: (v) =>
                cubit.update((s) => s.copyWith(showPredictions: v)),
          ),
        ),
      ],
    );
  }
}

/// A switch row with an icon, title and optional description.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(
        icon,
        color: value ? palette.accent : AppColors.textMuted,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _NameEditor extends StatefulWidget {
  const _NameEditor({required this.initial});

  final String initial;

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 20,
      decoration: InputDecoration(
        labelText: context.s.yourName,
        counterText: '',
        prefixIcon: const Icon(Icons.person_outline_rounded),
      ),
      onChanged: (value) => context.read<SettingsCubit>().update(
        (s) => s.copyWith(playerName: value.trim()),
      ),
    );
  }
}
