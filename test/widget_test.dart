import 'package:flutter_test/flutter_test.dart';
import 'package:live_score_app/models/match_model.dart';
import 'package:live_score_app/models/player_model.dart';
import 'package:live_score_app/services/match_service.dart';

void main() {
  group('MatchModel score parsing & formatting', () {
    test('parses standard cricket score correctly', () {
      final parsed = MatchModel.parseScore('178/4');
      expect(parsed.runs, 178);
      expect(parsed.wickets, 4);
    });

    test('parses zero or empty score gracefully', () {
      final parsedEmpty = MatchModel.parseScore('');
      expect(parsedEmpty.runs, 0);
      expect(parsedEmpty.wickets, 0);

      final parsedDash = MatchModel.parseScore('-');
      expect(parsedDash.runs, 0);
      expect(parsedDash.wickets, 0);
    });

    test('formats runs and wickets to score string', () {
      final formatted = MatchModel.formatScore(210, 6);
      expect(formatted, '210/6');
    });
  });

  group('PlayerModel & Playing 11 tests', () {
    test('PlayerModel serialization fromMap and toMap', () {
      const player = PlayerModel(
        name: 'Pat Cummins',
        role: 'Bowler',
        isCaptain: true,
      );
      final map = player.toMap();
      final fromMapPlayer = PlayerModel.fromMap(map);

      expect(fromMapPlayer.name, 'Pat Cummins');
      expect(fromMapPlayer.role, 'Bowler');
      expect(fromMapPlayer.isCaptain, true);
      expect(fromMapPlayer.isWicketKeeper, false);
    });

    test('MatchService provides 11 players for teams', () {
      final ausPlayers = MatchService.getDefaultPlayingEleven('Australia');
      expect(ausPlayers.length, 11);
      expect(ausPlayers.any((p) => p.isCaptain), true);
      expect(ausPlayers.any((p) => p.isWicketKeeper), true);

      final nzPlayers = MatchService.getDefaultPlayingEleven('New Zealand');
      expect(nzPlayers.length, 11);
      expect(nzPlayers.any((p) => p.isCaptain), true);
      expect(nzPlayers.any((p) => p.isWicketKeeper), true);
    });
  });
}
