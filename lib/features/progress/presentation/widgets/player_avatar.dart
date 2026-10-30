import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/avatar_frame.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../engine/chess_engine.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/settings_cubit.dart';
import '../../domain/player_progress.dart';

/// The piece type chosen as the player's avatar.
PieceType avatarPiece(AppSettings settings) =>
    PieceType.values.where((t) => t.name == settings.avatarId).firstOrNull ??
    PieceType.king;

/// The player's medallion: chosen piece and purchased frame.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    this.size = 58,
    this.color = PieceColor.white,
    this.glow = false,
  });

  final double size;
  final PieceColor color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    return PieceMedallion(
      piece: Piece(color, avatarPiece(settings)),
      frame: AvatarFrame.byId(settings.frameId),
      size: size,
      glow: glow,
    );
  }
}

/// The purchased title the player shows, or their rank title by default.
String displayTitle(AppStrings s, AppSettings settings, PlayerProgress p) =>
    settings.titleId.isEmpty
    ? s.rankTitle(p.title)
    : s.playerTitleName(settings.titleId);
