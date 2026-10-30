import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/chess_engine.dart';
import '../../game/domain/game_config.dart';
import '../domain/lan_connection.dart';
import '../domain/lan_message.dart';
import '../domain/lan_service.dart';

enum LanPhase { idle, hosting, connecting, ready, failed }

class LanLobbyState {
  const LanLobbyState({
    this.phase = LanPhase.idle,
    this.hosts = const [],
    this.addresses = const [],
    this.port,
    this.config,
  });

  final LanPhase phase;
  final List<DiscoveredHost> hosts;
  final List<String> addresses;
  final int? port;

  /// The game to start once both players are connected.
  final GameConfig? config;

  LanLobbyState copyWith({
    LanPhase? phase,
    List<DiscoveredHost>? hosts,
    List<String>? addresses,
    int? port,
    GameConfig? config,
  }) => LanLobbyState(
    phase: phase ?? this.phase,
    hosts: hosts ?? this.hosts,
    addresses: addresses ?? this.addresses,
    port: port ?? this.port,
    config: config ?? this.config,
  );
}

/// Hosts or joins a game on the local network and performs the handshake.
class LanLobbyCubit extends Cubit<LanLobbyState> {
  LanLobbyCubit(this._lan, {required this.playerName})
    : super(const LanLobbyState()) {
    if (_lan.isSupported) {
      _discovery = _lan.discover().listen(
        (hosts) => emit(state.copyWith(hosts: hosts)),
        onError: (Object _) {},
      );
    }
  }

  static const _handshakeTimeout = Duration(seconds: 12);

  final LanService _lan;

  /// The name shown to the other player.
  final String playerName;

  StreamSubscription<List<DiscoveredHost>>? _discovery;
  LanHostSession? _session;
  LanConnection? _connection;
  bool _handedOver = false;

  bool get isSupported => _lan.isSupported;

  Future<void> host({
    required PieceColor? color,
    required TimeControl? timeControl,
  }) async {
    final hostColor =
        color ?? (Random().nextBool() ? PieceColor.white : PieceColor.black);
    try {
      final session = await _lan.host(name: playerName);
      _session = session;
      final addresses = await _lan.localAddresses();
      emit(
        state.copyWith(
          phase: LanPhase.hosting,
          addresses: addresses,
          port: session.port,
        ),
      );
      final connection = await session.guest;
      _connection = connection;
      final hello =
          await connection.messages
                  .firstWhere((m) => m is HelloMessage)
                  .timeout(_handshakeTimeout)
              as HelloMessage;
      connection.send(
        WelcomeMessage(
          hostName: playerName,
          hostPlaysWhite: hostColor == PieceColor.white,
          minutes: timeControl?.minutes,
          incrementSeconds: timeControl?.incrementSeconds ?? 0,
        ),
      );
      await session.close();
      _session = null;
      _ready(
        GameConfig(
          mode: GameMode.lan,
          playerColor: hostColor,
          timeControl: timeControl,
          whiteName: hostColor == PieceColor.white
              ? playerName
              : _safeName(hello.name),
          blackName: hostColor == PieceColor.white
              ? _safeName(hello.name)
              : playerName,
          lanConnection: connection,
        ),
      );
    } on Object {
      if (isClosed || state.phase == LanPhase.idle) return;
      await _reset();
      emit(state.copyWith(phase: LanPhase.failed));
    }
  }

  Future<void> cancelHosting() async {
    await _reset();
    emit(state.copyWith(phase: LanPhase.idle));
  }

  /// Joins a host. [address] may include a port, as in `192.168.1.5:47480`.
  Future<void> join(String address, {int port = LanService.gamePort}) async {
    var host = address.trim();
    if (host.isEmpty) return;
    final separator = host.lastIndexOf(':');
    if (separator > 0) {
      port = int.tryParse(host.substring(separator + 1)) ?? port;
      host = host.substring(0, separator);
    }
    emit(state.copyWith(phase: LanPhase.connecting));
    try {
      final connection = await _lan.connect(host, port: port);
      _connection = connection;
      final welcomeFuture = connection.messages
          .firstWhere((m) => m is WelcomeMessage)
          .timeout(_handshakeTimeout);
      connection.send(HelloMessage(name: playerName));
      final welcome = await welcomeFuture as WelcomeMessage;
      final myColor = welcome.hostPlaysWhite
          ? PieceColor.black
          : PieceColor.white;
      final minutes = welcome.minutes;
      _ready(
        GameConfig(
          mode: GameMode.lan,
          playerColor: myColor,
          timeControl: minutes == null
              ? null
              : TimeControl(minutes, welcome.incrementSeconds),
          whiteName: myColor == PieceColor.white
              ? playerName
              : _safeName(welcome.hostName),
          blackName: myColor == PieceColor.white
              ? _safeName(welcome.hostName)
              : playerName,
          lanConnection: connection,
        ),
      );
    } on Object {
      if (isClosed) return;
      await _reset();
      emit(state.copyWith(phase: LanPhase.failed));
    }
  }

  /// Trims a name received from the other device to a sensible length.
  static String _safeName(String name) =>
      String.fromCharCodes(name.trim().runes.take(20));

  void _ready(GameConfig config) {
    if (isClosed) return;
    _handedOver = true;
    emit(state.copyWith(phase: LanPhase.ready, config: config));
  }

  Future<void> _reset() async {
    await _session?.close();
    _session = null;
    if (!_handedOver) await _connection?.close();
    _connection = null;
  }

  @override
  Future<void> close() async {
    await _discovery?.cancel();
    await _reset();
    return super.close();
  }
}
