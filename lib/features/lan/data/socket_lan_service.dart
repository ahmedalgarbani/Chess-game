import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/lan_connection.dart';
import '../domain/lan_message.dart';
import '../domain/lan_service.dart';

LanService createLanService() => SocketLanService();

/// LAN play over TCP, with UDP broadcast for discovering hosts.
class SocketLanService implements LanService {
  static const _appTag = 'ruqa-chess';
  static const _platform = MethodChannel('ruqa/lan');

  /// Android filters UDP broadcasts unless a multicast lock is held.
  Future<void> _setMulticastLock(bool acquire) async {
    if (!Platform.isAndroid) return;
    try {
      await _platform.invokeMethod<void>(
        acquire ? 'acquireMulticastLock' : 'releaseMulticastLock',
      );
    } on PlatformException {
      // Discovery still works on many devices; manual IP entry always does.
    } on MissingPluginException {
      // Not running inside the Android app (e.g. in tests).
    }
  }

  @override
  bool get isSupported => true;

  @override
  Future<List<String>> localAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return [
      for (final interface in interfaces)
        for (final address in interface.addresses) address.address,
    ];
  }

  @override
  Future<LanHostSession> host({required String name}) async {
    ServerSocket server;
    try {
      server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        LanService.gamePort,
      );
    } on SocketException {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    final announcer = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
      ..broadcastEnabled = true;
    final targets = await _broadcastTargets();
    return _SocketHostSession(server, announcer, targets, name);
  }

  Future<List<InternetAddress>> _broadcastTargets() async {
    final targets = <String>{'255.255.255.255'};
    for (final address in await localAddresses()) {
      final parts = address.split('.');
      if (parts.length == 4) {
        targets.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
      }
    }
    return [for (final t in targets) InternetAddress(t)];
  }

  @override
  Stream<List<DiscoveredHost>> discover() {
    late StreamController<List<DiscoveredHost>> controller;
    RawDatagramSocket? socket;
    Timer? timer;
    final seen = <String, (DiscoveredHost, DateTime)>{};

    void publish() {
      final now = DateTime.now();
      seen.removeWhere(
        (_, entry) => now.difference(entry.$2) > const Duration(seconds: 4),
      );
      if (!controller.isClosed) {
        controller.add([for (final entry in seen.values) entry.$1]);
      }
    }

    controller = StreamController<List<DiscoveredHost>>(
      onListen: () async {
        await _setMulticastLock(true);
        try {
          socket = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4,
            LanService.discoveryPort,
            reuseAddress: true,
          );
        } on SocketException catch (error) {
          controller.addError(error);
          return;
        }
        socket!.listen((event) {
          if (event != RawSocketEvent.read) return;
          final datagram = socket!.receive();
          if (datagram == null) return;
          try {
            final json = jsonDecode(utf8.decode(datagram.data));
            if (json is! Map || json['app'] != _appTag) return;
            final host = DiscoveredHost(
              name: '${json['name']}',
              address: datagram.address.address,
              port: json['port'] as int? ?? LanService.gamePort,
            );
            seen[host.address] = (host, DateTime.now());
          } on FormatException {
            return;
          }
        });
        timer = Timer.periodic(const Duration(seconds: 1), (_) => publish());
        publish();
      },
      onCancel: () {
        timer?.cancel();
        socket?.close();
        _setMulticastLock(false);
      },
    );
    return controller.stream;
  }

  @override
  Future<LanConnection> connect(
    String address, {
    int port = LanService.gamePort,
  }) async {
    final socket = await Socket.connect(
      address,
      port,
      timeout: const Duration(seconds: 6),
    );
    socket.setOption(SocketOption.tcpNoDelay, true);
    return SocketLanConnection(socket);
  }
}

class _SocketHostSession implements LanHostSession {
  _SocketHostSession(this._server, this._announcer, this._targets, this._name) {
    _announce();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _announce());
    _subscription = _server.listen((socket) {
      if (_guest.isCompleted) {
        socket.destroy();
        return;
      }
      socket.setOption(SocketOption.tcpNoDelay, true);
      _stopAnnouncing();
      _guest.complete(SocketLanConnection(socket));
    });
  }

  final ServerSocket _server;
  final RawDatagramSocket _announcer;
  final List<InternetAddress> _targets;
  final String _name;
  final Completer<LanConnection> _guest = Completer();
  late final Timer _timer;
  late final StreamSubscription<Socket> _subscription;

  @override
  int get port => _server.port;

  @override
  Future<LanConnection> get guest => _guest.future;

  void _announce() {
    final payload = utf8.encode(
      jsonEncode({
        'app': SocketLanService._appTag,
        'name': _name,
        'port': _server.port,
      }),
    );
    for (final target in _targets) {
      try {
        _announcer.send(payload, target, LanService.discoveryPort);
      } on SocketException {
        // Some networks reject broadcasts; manual IP entry still works.
      }
    }
  }

  void _stopAnnouncing() {
    _timer.cancel();
    _announcer.close();
  }

  @override
  Future<void> close() async {
    if (_timer.isActive) _stopAnnouncing();
    await _subscription.cancel();
    await _server.close();
  }
}

/// A newline-delimited JSON channel over a TCP socket.
class SocketLanConnection implements LanConnection {
  SocketLanConnection(this._socket) {
    _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _onLine,
          onError: (Object _) => _controller.close(),
          onDone: _controller.close,
          cancelOnError: true,
        );
  }

  final Socket _socket;
  final StreamController<LanMessage> _controller = StreamController.broadcast();
  bool _closed = false;

  @override
  Stream<LanMessage> get messages => _controller.stream;

  void _onLine(String line) {
    try {
      final json = jsonDecode(line);
      if (json is! Map<String, Object?>) return;
      final message = LanMessage.fromJson(json);
      if (message != null && !_controller.isClosed) _controller.add(message);
    } on FormatException {
      return;
    }
  }

  @override
  void send(LanMessage message) {
    if (_closed) return;
    try {
      _socket.write('${jsonEncode(message.toJson())}\n');
    } on SocketException {
      _controller.close();
    } on StateError {
      _controller.close();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _socket.flush();
    } on Object {
      // The peer may already be gone.
    }
    _socket.destroy();
    await _controller.close();
  }
}
