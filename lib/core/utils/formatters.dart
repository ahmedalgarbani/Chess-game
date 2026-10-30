/// Formats a clock reading: `m:ss`, or `s.t` under ten seconds.
String formatClock(Duration time) {
  if (time < const Duration(seconds: 10)) {
    final tenths = (time.inMilliseconds / 100).floor();
    return '${tenths ~/ 10}.${tenths % 10}';
  }
  final minutes = time.inMinutes;
  final seconds = time.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Formats centipawns as a signed pawn value, e.g. `+1.3`.
String formatPawns(int centipawns) {
  final pawns = (centipawns.abs() / 100).toStringAsFixed(1);
  return centipawns >= 0 ? '+$pawns' : '-$pawns';
}

/// Formats a date and time as `yyyy/mm/dd hh:mm`.
String formatDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}/${two(time.month)}/${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}
