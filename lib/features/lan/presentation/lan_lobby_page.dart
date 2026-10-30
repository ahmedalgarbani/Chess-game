import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/routes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../core/widgets/royal_button.dart';
import '../../game/domain/game_config.dart';
import '../../game/presentation/pages/game_page.dart';
import '../../game/presentation/pages/game_setup_sheet.dart';
import '../../settings/presentation/settings_cubit.dart';
import '../domain/lan_service.dart';
import 'lan_lobby_cubit.dart';

class LanLobbyPage extends StatelessWidget {
  const LanLobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.read<SettingsCubit>().state.playerName;
    return BlocProvider(
      create: (context) => LanLobbyCubit(
        context.read<LanService>(),
        playerName: name.isEmpty ? context.s.friend : name,
      ),
      child: const _LanLobbyView(),
    );
  }
}

class _LanLobbyView extends StatefulWidget {
  const _LanLobbyView();

  @override
  State<_LanLobbyView> createState() => _LanLobbyViewState();
}

class _LanLobbyViewState extends State<_LanLobbyView> {
  final _address = TextEditingController();
  ColorChoice _color = ColorChoice.white;
  TimeControl? _time;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return BlocConsumer<LanLobbyCubit, LanLobbyState>(
      listenWhen: (a, b) => a.phase != b.phase,
      listener: (context, state) {
        if (state.phase == LanPhase.ready && state.config != null) {
          AppRoutes.replace(context, GamePage(config: state.config!));
        } else if (state.phase == LanPhase.failed) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s.connectionFailed)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<LanLobbyCubit>();
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(title: Text(s.lanTitle)),
          body: RoyalBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_rounded,
                          color: AppColors.sapphire,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cubit.isSupported ? s.lanIntro : s.lanUnsupported,
                            style: const TextStyle(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (cubit.isSupported) ...[
                    const SizedBox(height: 18),
                    if (state.phase == LanPhase.hosting)
                      _WaitingCard(state: state, onCancel: cubit.cancelHosting)
                    else
                      _HostCard(
                        color: _color,
                        time: _time,
                        busy: state.phase == LanPhase.connecting,
                        onColor: (value) => setState(() => _color = value),
                        onTime: (value) => setState(() => _time = value),
                        onHost: () => cubit.host(
                          color: _color == ColorChoice.random
                              ? null
                              : _color.resolve(),
                          timeControl: _time,
                        ),
                      ),
                    const SizedBox(height: 18),
                    SectionTitle(s.joinGame),
                    _JoinCard(
                      state: state,
                      address: _address,
                      onJoin: (host) =>
                          cubit.join(host.address, port: host.port),
                      onManualJoin: () => cubit.join(_address.text),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.color,
    required this.time,
    required this.busy,
    required this.onColor,
    required this.onTime,
    required this.onHost,
  });

  final ColorChoice color;
  final TimeControl? time;
  final bool busy;
  final ValueChanged<ColorChoice> onColor;
  final ValueChanged<TimeControl?> onTime;
  final VoidCallback onHost;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(s.hostGame),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.hostGameDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                s.yourColor,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ColorChoiceSelector(value: color, onChanged: onColor),
              const SizedBox(height: 14),
              Text(
                s.timeControl,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TimeControlSelector(value: time, onChanged: onTime),
              const SizedBox(height: 16),
              RoyalButton(
                label: s.startHosting,
                icon: Icons.cell_tower_rounded,
                onPressed: busy ? null : onHost,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.state, required this.onCancel});

  final LanLobbyState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return GlassCard(
      borderColor: AppColors.gold.withValues(alpha: 0.6),
      child: Column(
        children: [
          const SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
          const SizedBox(height: 14),
          Text(
            s.waitingForOpponent,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Text(s.yourAddress, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          for (final address in state.addresses)
            SelectableText(
              state.port == null || state.port == LanService.gamePort
                  ? address
                  : '$address:${state.port}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.goldLight,
                letterSpacing: 1,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            s.addressHelp,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          GhostButton(
            label: s.cancel,
            icon: Icons.close_rounded,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.state,
    required this.address,
    required this.onJoin,
    required this.onManualJoin,
  });

  final LanLobbyState state;
  final TextEditingController address;
  final ValueChanged<DiscoveredHost> onJoin;
  final VoidCallback onManualJoin;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final connecting = state.phase == LanPhase.connecting;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.hosts.isEmpty)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.sapphire,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.searchingGames,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            )
          else
            for (final host in state.hosts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.gold,
                ),
                title: Text(
                  s.hostedBy(host.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(host.address),
                trailing: FilledButton(
                  onPressed: connecting ? null : () => onJoin(host),
                  child: Text(s.connect),
                ),
              ),
          if (state.hosts.isEmpty) ...[
            const SizedBox(height: 6),
            Text(s.noGamesFound, style: Theme.of(context).textTheme.bodySmall),
          ],
          const Divider(height: 28, color: AppColors.divider),
          Text(
            s.enterAddress,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: address,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(hintText: s.addressHint),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: connecting ? null : onManualJoin,
                  child: connecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s.connect),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
