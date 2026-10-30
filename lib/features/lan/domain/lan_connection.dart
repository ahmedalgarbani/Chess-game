import 'lan_message.dart';

/// A live connection to the other player's device.
abstract interface class LanConnection {
  /// Incoming messages. The stream closes when the connection drops.
  Stream<LanMessage> get messages;

  void send(LanMessage message);

  Future<void> close();
}
