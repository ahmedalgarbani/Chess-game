import '../domain/lan_connection.dart';
import '../domain/lan_service.dart';

LanService createLanService() => UnsupportedLanService();

/// Used on platforms without socket access (the web).
class UnsupportedLanService implements LanService {
  @override
  bool get isSupported => false;

  @override
  Future<List<String>> localAddresses() async => const [];

  @override
  Future<LanHostSession> host({required String name}) =>
      throw UnsupportedError('LAN play is not available on this platform');

  @override
  Stream<List<DiscoveredHost>> discover() => const Stream.empty();

  @override
  Future<LanConnection> connect(
    String address, {
    int port = LanService.gamePort,
  }) => throw UnsupportedError('LAN play is not available on this platform');
}
