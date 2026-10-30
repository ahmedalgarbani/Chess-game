import 'dart:async';

import 'package:chess_game/features/lan/data/socket_lan_service.dart';
import 'package:chess_game/features/lan/domain/lan_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('messages survive a JSON round trip', () {
    const messages = <LanMessage>[
      HelloMessage(name: 'أحمد'),
      WelcomeMessage(
        hostName: 'Sara',
        hostPlaysWhite: false,
        minutes: 5,
        incrementSeconds: 3,
      ),
      MoveMessage(uci: 'e7e8q', whiteMs: 1000, blackMs: 2000),
      ResignMessage(),
      DrawOfferMessage(),
      DrawReplyMessage(accepted: true),
      RematchOfferMessage(),
      RematchReplyMessage(accepted: false),
      ReactionMessage('🔥'),
      TimeoutMessage(),
      ByeMessage(),
    ];
    for (final message in messages) {
      final decoded = LanMessage.fromJson(message.toJson());
      expect(decoded, isNotNull);
      expect(decoded!.toJson(), message.toJson());
    }
    expect(LanMessage.fromJson({'type': 'unknown'}), isNull);
    expect(LanMessage.fromJson({'type': 'move', 'uci': 42}), isNull);
  });

  test('host and guest exchange messages over a real socket', () async {
    final service = SocketLanService();
    final host = await service.host(name: 'Host');
    final guest = await service.connect('127.0.0.1', port: host.port);
    final hostSide = await host.guest.timeout(const Duration(seconds: 5));

    final received = Completer<LanMessage>();
    hostSide.messages.listen(received.complete);
    guest.send(const HelloMessage(name: 'Guest'));
    final hello = await received.future.timeout(const Duration(seconds: 5));
    expect(hello, isA<HelloMessage>());
    expect((hello as HelloMessage).name, 'Guest');

    final reply = guest.messages.first;
    hostSide.send(const MoveMessage(uci: 'e2e4'));
    final move = await reply.timeout(const Duration(seconds: 5));
    expect((move as MoveMessage).uci, 'e2e4');

    final closed = hostSide.messages.toList();
    await guest.close();
    await closed.timeout(const Duration(seconds: 5));
    await hostSide.close();
    await host.close();
  });
}
