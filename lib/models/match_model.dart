import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final String teamALogoUrl;
  final String teamBLogoUrl;
  final String scoreA;
  final String scoreB;
  final String status;
  final Timestamp matchDate;
  final String venue;
  final String oversA;
  final String oversB;
  final List<String> recentBalls;
  final List<PlayerModel> teamAPlayers;
  final List<PlayerModel> teamBPlayers;

  const MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.teamALogoUrl,
    required this.teamBLogoUrl,
    required this.scoreA,
    required this.scoreB,
    required this.status,
    required this.matchDate,
    required this.venue,
    this.oversA = '',
    this.oversB = '',
    this.recentBalls = const [],
    this.teamAPlayers = const [],
    this.teamBPlayers = const [],
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse recent balls
    final recentRaw = data['recentBalls'];
    List<String> parsedRecentBalls = [];
    if (recentRaw is List) {
      parsedRecentBalls = recentRaw.map((e) => e.toString()).toList();
    }

    // Parse team A playing 11
    final rawPlayersA = data['teamAPlayers'];
    final List<PlayerModel> playersA = [];
    if (rawPlayersA is List) {
      for (final item in rawPlayersA) {
        if (item is Map) {
          playersA.add(PlayerModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Parse team B playing 11
    final rawPlayersB = data['teamBPlayers'];
    final List<PlayerModel> playersB = [];
    if (rawPlayersB is List) {
      for (final item in rawPlayersB) {
        if (item is Map) {
          playersB.add(PlayerModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return MatchModel(
      id: doc.id,
      teamA: data['teamA'] as String? ?? 'Team A',
      teamB: data['teamB'] as String? ?? 'Team B',
      teamALogoUrl: data['teamALogoUrl'] as String? ?? '',
      teamBLogoUrl: data['teamBLogoUrl'] as String? ?? '',
      scoreA: data['scoreA'] as String? ?? '0/0',
      scoreB: data['scoreB'] as String? ?? '0/0',
      status: data['status'] as String? ?? 'Upcoming',
      matchDate: data['matchDate'] is Timestamp
          ? data['matchDate'] as Timestamp
          : Timestamp.now(),
      venue: data['venue'] as String? ?? 'TBD',
      oversA: data['oversA'] as String? ?? '',
      oversB: data['oversB'] as String? ?? '',
      recentBalls: parsedRecentBalls,
      teamAPlayers: playersA,
      teamBPlayers: playersB,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamA': teamA,
      'teamB': teamB,
      'teamALogoUrl': teamALogoUrl,
      'teamBLogoUrl': teamBLogoUrl,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'status': status,
      'matchDate': matchDate,
      'venue': venue,
      'oversA': oversA,
      'oversB': oversB,
      'recentBalls': recentBalls,
      'teamAPlayers': teamAPlayers.map((p) => p.toMap()).toList(),
      'teamBPlayers': teamBPlayers.map((p) => p.toMap()).toList(),
    };
  }

  /// Parses cricket score string like "125/4" into runs and wickets integers.
  static ({int runs, int wickets}) parseScore(String score) {
    final clean = score.trim();
    if (clean.isEmpty || clean == '-' || clean == '0') {
      return (runs: 0, wickets: 0);
    }
    if (clean.contains('/')) {
      final parts = clean.split('/');
      final runs = int.tryParse(parts[0].trim()) ?? 0;
      final wickets = int.tryParse(parts.length > 1 ? parts[1].trim() : '0') ?? 0;
      return (runs: runs, wickets: wickets);
    }
    final runs = int.tryParse(clean) ?? 0;
    return (runs: runs, wickets: 0);
  }

  /// Formats runs and wickets into standard cricket score string "125/4"
  static String formatScore(int runs, int wickets) {
    return '$runs/$wickets';
  }
}
