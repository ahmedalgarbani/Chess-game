/// Messages exchanged between two devices playing over the local network.
/// They travel as one JSON object per line over a TCP socket.
sealed class LanMessage {
  const LanMessage();

  String get type;

  Map<String, Object?> get fields => const {};

  Map<String, Object?> toJson() => {'type': type, ...fields};

  /// Parses a message, returning null for unknown or malformed input.
  static LanMessage? fromJson(Map<String, Object?> json) {
    try {
      return switch (json['type']) {
        'hello' => HelloMessage(
          name: json['name'] as String? ?? '',
          version: json['version'] as int? ?? 0,
        ),
        'welcome' => WelcomeMessage(
          hostName: json['hostName'] as String? ?? '',
          hostPlaysWhite: json['hostPlaysWhite'] as bool? ?? true,
          minutes: json['minutes'] as int?,
          incrementSeconds: json['increment'] as int? ?? 0,
        ),
        'move' => MoveMessage(
          uci: json['uci'] as String,
          whiteMs: json['whiteMs'] as int?,
          blackMs: json['blackMs'] as int?,
        ),
        'resign' => const ResignMessage(),
        'drawOffer' => const DrawOfferMessage(),
        'drawReply' => DrawReplyMessage(
          accepted: json['accepted'] as bool? ?? false,
        ),
        'rematchOffer' => const RematchOfferMessage(),
        'rematchReply' => RematchReplyMessage(
          accepted: json['accepted'] as bool? ?? false,
        ),
        'reaction' => ReactionMessage(json['emoji'] as String? ?? ''),
        'timeout' => const TimeoutMessage(),
        'bye' => const ByeMessage(),
        _ => null,
      };
    } on TypeError {
      return null;
    }
  }
}

/// Sent by the guest right after connecting.
class HelloMessage extends LanMessage {
  const HelloMessage({required this.name, this.version = protocolVersion});

  static const int protocolVersion = 1;

  final String name;
  final int version;

  @override
  String get type => 'hello';

  @override
  Map<String, Object?> get fields => {'name': name, 'version': version};
}

/// The host's answer to [HelloMessage], carrying the game settings.
class WelcomeMessage extends LanMessage {
  const WelcomeMessage({
    required this.hostName,
    required this.hostPlaysWhite,
    this.minutes,
    this.incrementSeconds = 0,
  });

  final String hostName;
  final bool hostPlaysWhite;

  /// Null when the game has no clock.
  final int? minutes;
  final int incrementSeconds;

  @override
  String get type => 'welcome';

  @override
  Map<String, Object?> get fields => {
    'hostName': hostName,
    'hostPlaysWhite': hostPlaysWhite,
    'minutes': minutes,
    'increment': incrementSeconds,
  };
}

class MoveMessage extends LanMessage {
  const MoveMessage({required this.uci, this.whiteMs, this.blackMs});

  final String uci;

  /// The sender's clock readings after the move, to keep clocks in sync.
  final int? whiteMs;
  final int? blackMs;

  @override
  String get type => 'move';

  @override
  Map<String, Object?> get fields => {
    'uci': uci,
    'whiteMs': whiteMs,
    'blackMs': blackMs,
  };
}

class ResignMessage extends LanMessage {
  const ResignMessage();

  @override
  String get type => 'resign';
}

class DrawOfferMessage extends LanMessage {
  const DrawOfferMessage();

  @override
  String get type => 'drawOffer';
}

class DrawReplyMessage extends LanMessage {
  const DrawReplyMessage({required this.accepted});

  final bool accepted;

  @override
  String get type => 'drawReply';

  @override
  Map<String, Object?> get fields => {'accepted': accepted};
}

class RematchOfferMessage extends LanMessage {
  const RematchOfferMessage();

  @override
  String get type => 'rematchOffer';
}

class RematchReplyMessage extends LanMessage {
  const RematchReplyMessage({required this.accepted});

  final bool accepted;

  @override
  String get type => 'rematchReply';

  @override
  Map<String, Object?> get fields => {'accepted': accepted};
}

/// A quick emoji reaction.
class ReactionMessage extends LanMessage {
  const ReactionMessage(this.emoji);

  final String emoji;

  @override
  String get type => 'reaction';

  @override
  Map<String, Object?> get fields => {'emoji': emoji};
}

/// The sender ran out of time.
class TimeoutMessage extends LanMessage {
  const TimeoutMessage();

  @override
  String get type => 'timeout';
}

/// The sender is leaving the game.
class ByeMessage extends LanMessage {
  const ByeMessage();

  @override
  String get type => 'bye';
}
