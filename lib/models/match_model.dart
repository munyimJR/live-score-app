import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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
    };
  }

  /// Parses cricket score string like "125/4" into runs and wickets integers.
  /// Handles fallback/empty cases gracefully.
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
