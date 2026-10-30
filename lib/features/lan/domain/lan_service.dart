import 'lan_connection.dart';

/// A game advertised by a host on the local network.
class DiscoveredHost {
  const DiscoveredHost({
    required this.name,
    required this.address,
    required this.port,
  });

  final String name;
  final String address;
  final int port;
}

/// A hosted game waiting for a guest.
abstract interface class LanHostSession {
  int get port;

  /// Completes when a guest connects.
  Future<LanConnection> get guest;

  Future<void> close();
}

/// Hosting, discovering and joining games on the same Wi-Fi network.
abstract interface class LanService {
  static const int gamePort = 47474;
  static const int discoveryPort = 47475;

  /// False on platforms without raw sockets (the web).
  bool get isSupported;

  /// This device's IPv4 addresses on the local network.
  Future<List<String>> localAddresses();

  Future<LanHostSession> host({required String name});

  /// Hosts currently advertising on the network, refreshed periodically.
  Stream<List<DiscoveredHost>> discover();

  Future<LanConnection> connect(
    String address, {
    int port = LanService.gamePort,
  });
}
