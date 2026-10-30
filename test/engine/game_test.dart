import 'package:chess_game/engine/chess_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChessGame', () {
    test('records SAN for common moves', () {
      final game = ChessGame();
      final sans = [
        for (final uci in ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', 'a7a6'])
          game.playUci(uci)!.san,
      ];
      expect(sans, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6']);
      expect(game.playUci('b5c6')!.san, 'Bxc6');
      expect(game.playUci('d7c6')!.san, 'dxc6');
      expect(game.playUci('e1g1')!.san, 'O-O');
    });

    test('detects fool\'s mate', () {
      final game = ChessGame.fromMoves(['f2f3', 'e7e5', 'g2g4']);
      final record = game.playUci('d8h4')!;
      expect(record.san, 'Qh4#');
      expect(game.status, GameStatus.checkmate);
      expect(game.winner, PieceColor.black);
    });

    test('disambiguates knight moves', () {
      final game = ChessGame(fen: '4k3/8/8/8/8/8/8/N1N1K3 w - - 0 1');
      expect(game.playUci('a1b3')?.san, 'Nab3');
    });

    test('promotion and stalemate detection', () {
      final game = ChessGame(fen: '7k/5P2/6K1/8/8/8/8/8 w - - 0 1');
      expect(
        game.findMove(Square.parse('f7'), Square.parse('f8'))!.promotion,
        PieceType.queen,
      );
      expect(game.playUci('f7f8q')!.san, 'f8=Q#');
      expect(game.isCheckmate, isTrue);

      final stalemate = ChessGame(fen: '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1');
      expect(stalemate.status, GameStatus.stalemate);
    });

    test('en passant capture', () {
      final game = ChessGame.fromMoves(['e2e4', 'a7a6', 'e4e5', 'd7d5']);
      final record = game.playUci('e5d6')!;
      expect(record.san, 'exd6');
      expect(record.move.isEnPassant, isTrue);
      expect(game.pieceAt(Square.parse('d5')), isNull);
    });

    test('threefold repetition', () {
      final game = ChessGame();
      for (var i = 0; i < 2; i++) {
        for (final uci in ['g1f3', 'g8f6', 'f3g1', 'f6g8']) {
          game.playUci(uci);
        }
      }
      expect(game.status, GameStatus.threefoldRepetition);
      game.undo();
      expect(game.status, GameStatus.ongoing);
    });

    test('insufficient material', () {
      expect(
        ChessGame(fen: '8/8/4k3/8/8/2B5/8/4K3 w - - 0 1').status,
        GameStatus.insufficientMaterial,
      );
      expect(
        ChessGame(fen: '8/8/4k3/8/8/2R5/8/4K3 w - - 0 1').status,
        GameStatus.ongoing,
      );
    });

    test('undo restores the position', () {
      final game = ChessGame();
      game.playUci('e2e4');
      game.playUci('e7e5');
      game.undo();
      game.undo();
      expect(game.fen, startingFen);
      expect(game.history, isEmpty);
    });

    test('positions without kings are supported for lessons', () {
      final game = ChessGame(fen: '8/8/8/8/8/8/8/R7 w - - 0 1');
      expect(game.legalMoves.length, 14);
    });
  });
}
