import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/chess_ui/piece_painter.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/avatar_frame.dart';
import '../../../core/theme/board_theme.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/royal_background.dart';
import '../../../engine/chess_engine.dart';
import '../../progress/domain/achievement.dart';
import '../../progress/domain/player_progress.dart';
import '../../progress/domain/shop_items.dart';
import '../../progress/presentation/progress_cubit.dart';
import '../../progress/presentation/widgets/player_avatar.dart';
import '../../settings/presentation/settings_cubit.dart';

/// Where coins are spent: app themes, boards, pieces, avatar frames,
/// titles and boosts.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final coins = context.select<ProgressCubit, int>((c) => c.state.coins);
    return DefaultTabController(
      length: 6,
      initialIndex: initialTab,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(s.shopTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(child: CoinChip(coins: coins, compact: true)),
            ),
          ],
        ),
        body: RoyalBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text(
                    s.shopSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  indicator: BoxDecoration(
                    gradient: palette.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tabs: [
                    Tab(text: s.appThemesTab),
                    Tab(text: s.boardThemes),
                    Tab(text: s.pieceStyles),
                    Tab(text: s.avatarTab),
                    Tab(text: s.titlesTab),
                    Tab(text: s.boostsTab),
                  ],
                ),
                const SizedBox(height: 8),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _AppThemesTab(),
                      _BoardsTab(),
                      _PiecesTab(),
                      _AvatarTab(),
                      _TitlesTab(),
                      _BoostsTab(),
                    ],
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

/// Confirms and performs a purchase, then reports the result.
Future<void> _purchase(
  BuildContext context, {
  required String name,
  required int price,
  required List<Achievement>? Function() buy,
  VoidCallback? onBought,
}) async {
  final s = context.s;
  final messenger = ScaffoldMessenger.of(context);
  if (context.read<ProgressCubit>().state.coins < price) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${s.notEnoughCoins} ${s.earnCoinsHint}')),
      );
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const CoinIcon(size: 40),
      title: Text(s.confirmPurchase(name, price), textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.buy),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final earned = buy();
  if (earned == null) {
    messenger.showSnackBar(SnackBar(content: Text(s.notEnoughCoins)));
    return;
  }
  onBought?.call();
  final unlocked = [
    for (final a in earned) '${s.achievementTitle(a)} (+${a.coins})',
  ];
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          [
            s.purchased(name),
            if (unlocked.isNotEmpty)
              '${s.newAchievement}: ${unlocked.join('، ')}',
          ].join('\n'),
        ),
      ),
    );
}

/// The state-dependent button of a cosmetic: in use, use, or buy.
class _CosmeticAction extends StatelessWidget {
  const _CosmeticAction({
    required this.kind,
    required this.id,
    required this.price,
    required this.name,
    required this.selected,
    required this.onUse,
  });

  final CosmeticKind kind;
  final String id;
  final int price;
  final String name;
  final bool selected;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final progress = context.watch<ProgressCubit>().state;
    if (selected) {
      return Chip(
        avatar: Icon(Icons.check_rounded, size: 18, color: palette.onAccent),
        label: Text(s.inUse),
        backgroundColor: palette.accent,
        labelStyle: TextStyle(color: palette.onAccent),
      );
    }
    if (progress.owns(kind, id)) {
      return OutlinedButton(onPressed: onUse, child: Text(s.use));
    }
    return FilledButton.icon(
      onPressed: () => _purchase(
        context,
        name: name,
        price: price,
        buy: () => context.read<ProgressCubit>().buy(kind, id, price),
        onBought: onUse,
      ),
      icon: const CoinIcon(size: 16),
      label: Text('$price'),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.preview,
    required this.name,
    required this.action,
    this.selected = false,
    this.subtitle,
  });

  final Widget preview;
  final String name;
  final String? subtitle;
  final Widget action;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderColor: selected ? context.palette.accent : null,
        child: Row(
          children: [
            preview,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            action,
          ],
        ),
      ),
    );
  }
}

class _AppThemesTab extends StatelessWidget {
  const _AppThemesTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final theme in AppPalette.all)
          _ItemRow(
            preview: _ThemePreview(palette: theme),
            name: s.appThemeName(theme.id),
            selected: settings.appThemeId == theme.id,
            action: _CosmeticAction(
              kind: CosmeticKind.appTheme,
              id: theme.id,
              price: theme.price,
              name: s.appThemeName(theme.id),
              selected: settings.appThemeId == theme.id,
              onUse: () => context.read<SettingsCubit>().update(
                (s) => s.copyWith(appThemeId: theme.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 56,
      decoration: BoxDecoration(
        gradient: palette.backgroundGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: palette.accentGradient,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: palette.accentGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.surfaceHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardsTab extends StatelessWidget {
  const _BoardsTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    final style = PieceStyle.byId(settings.pieceStyleId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final theme in BoardTheme.all)
          _ItemRow(
            preview: _BoardPreview(theme: theme, style: style),
            name: s.boardThemeName(theme.id),
            selected: settings.boardThemeId == theme.id,
            action: _CosmeticAction(
              kind: CosmeticKind.board,
              id: theme.id,
              price: theme.price,
              name: s.boardThemeName(theme.id),
              selected: settings.boardThemeId == theme.id,
              onUse: () => context.read<SettingsCubit>().update(
                (s) => s.copyWith(boardThemeId: theme.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _PiecesTab extends StatelessWidget {
  const _PiecesTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsCubit>().state;
    final board = BoardTheme.byId(settings.boardThemeId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final style in PieceStyle.all)
          _ItemRow(
            preview: _BoardPreview(theme: board, style: style),
            name: s.pieceStyleName(style.id),
            selected: settings.pieceStyleId == style.id,
            action: _CosmeticAction(
              kind: CosmeticKind.pieces,
              id: style.id,
              price: style.price,
              name: s.pieceStyleName(style.id),
              selected: settings.pieceStyleId == style.id,
              onUse: () => context.read<SettingsCubit>().update(
                (s) => s.copyWith(pieceStyleId: style.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.theme, required this.style});

  final BoardTheme theme;
  final PieceStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            for (final (index, piece) in const [
              Piece.whiteKing,
              Piece.blackQueen,
            ].indexed)
              Expanded(
                child: ColoredBox(
                  color: index.isEven ? theme.light : theme.dark,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: PieceView(piece: piece, style: style, shadow: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarTab extends StatelessWidget {
  const _AvatarTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final settings = context.watch<SettingsCubit>().state;
    final selectedPiece = avatarPiece(settings);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Center(child: const PlayerAvatar(size: 96, glow: true)),
        const SizedBox(height: 16),
        SectionTitle(s.chooseAvatarPiece),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final type in PieceType.values.reversed)
              GestureDetector(
                onTap: () => context.read<SettingsCubit>().update(
                  (s) => s.copyWith(avatarId: type.name),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: type == selectedPiece
                        ? palette.accent.withValues(alpha: 0.2)
                        : AppColors.surfaceGlass,
                    border: Border.all(
                      color: type == selectedPiece
                          ? palette.accent
                          : palette.outline,
                      width: type == selectedPiece ? 2 : 1,
                    ),
                  ),
                  child: PieceView(
                    piece: Piece(PieceColor.white, type),
                    style: PieceStyle.royal,
                    shadow: false,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        SectionTitle(s.frames),
        for (final frame in AvatarFrame.all)
          _ItemRow(
            preview: PieceMedallion(
              piece: Piece(PieceColor.white, selectedPiece),
              frame: frame,
              size: 54,
            ),
            name: s.frameName(frame.id),
            selected: settings.frameId == frame.id,
            action: _CosmeticAction(
              kind: CosmeticKind.frame,
              id: frame.id,
              price: frame.price,
              name: s.frameName(frame.id),
              selected: settings.frameId == frame.id,
              onUse: () => context.read<SettingsCubit>().update(
                (s) => s.copyWith(frameId: frame.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _TitlesTab extends StatelessWidget {
  const _TitlesTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = context.palette;
    final settings = context.watch<SettingsCubit>().state;
    final progress = context.watch<ProgressCubit>().state;
    Widget preview(String text) => Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: palette.accent.withValues(alpha: 0.12),
        border: Border.all(color: palette.outline),
      ),
      child: Icon(Icons.military_tech_rounded, color: palette.accentLight),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ItemRow(
          preview: preview(''),
          name: s.rankTitleOption,
          subtitle: s.rankTitle(progress.title),
          selected: settings.titleId.isEmpty,
          action: _CosmeticAction(
            kind: CosmeticKind.title,
            id: '',
            price: 0,
            name: s.rankTitleOption,
            selected: settings.titleId.isEmpty,
            onUse: () => context.read<SettingsCubit>().update(
              (s) => s.copyWith(titleId: ''),
            ),
          ),
        ),
        for (final MapEntry(key: id, value: price)
            in TitleCatalog.prices.entries)
          _ItemRow(
            preview: preview(id),
            name: s.playerTitleName(id),
            selected: settings.titleId == id,
            action: _CosmeticAction(
              kind: CosmeticKind.title,
              id: id,
              price: price,
              name: s.playerTitleName(id),
              selected: settings.titleId == id,
              onUse: () => context.read<SettingsCubit>().update(
                (s) => s.copyWith(titleId: id),
              ),
            ),
          ),
      ],
    );
  }
}

class _BoostsTab extends StatelessWidget {
  const _BoostsTab();

  static int _owned(PlayerProgress progress, Boost boost) => switch (boost) {
    Boost.hintPack => progress.hintTokens,
    Boost.xpBooster => progress.xpBoostGames,
    Boost.streakShield => progress.streakShields,
  };

  static (IconData, Color) _style(Boost boost) => switch (boost) {
    Boost.hintPack => (Icons.lightbulb_rounded, AppColors.emerald),
    Boost.xpBooster => (Icons.bolt_rounded, AppColors.amber),
    Boost.streakShield => (Icons.shield_moon_rounded, AppColors.sapphire),
  };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final progress = context.watch<ProgressCubit>().state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final boost in Boost.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      final (icon, color) = _style(boost);
                      return Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.16),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Icon(icon, color: color, size: 30),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.boostName(boost),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.boostDescription(boost),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.boostOwned(_owned(progress, boost)),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: context.palette.accentLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _purchase(
                      context,
                      name: s.boostName(boost),
                      price: boost.price,
                      buy: () => context.read<ProgressCubit>().buyBoost(boost),
                    ),
                    icon: const CoinIcon(size: 16),
                    label: Text('${boost.price}'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          s.earnCoinsHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
