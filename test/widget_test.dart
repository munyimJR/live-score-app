import 'package:flutter_test/flutter_test.dart';
import 'package:live_score_app/models/match_model.dart';

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
}
