import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchService {
  final FirebaseFirestore _firestore;

  MatchService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matchesRef =>
      _firestore.collection('matches');

  /// Streams all matches from Firestore in real-time.
  Stream<List<MatchModel>> getMatchesStream() {
    return _matchesRef.snapshots().map((snapshot) {
      final matches = snapshot.docs
          .map((doc) => MatchModel.fromFirestore(doc))
          .toList();

      // Sort: Live first, then Upcoming, then Finished. Within status, by date.
      matches.sort((a, b) {
        final statusPriority = {'Live': 0, 'Upcoming': 1, 'Finished': 2};
        final priorityA = statusPriority[a.status] ?? 3;
        final priorityB = statusPriority[b.status] ?? 3;
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return b.matchDate.compareTo(a.matchDate);
      });

      return matches;
    });
  }

  /// Streams a single match document by id in real-time.
  Stream<MatchModel?> getMatchStream(String matchId) {
    return _matchesRef.doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MatchModel.fromFirestore(doc);
    });
  }

  /// Updates score and status for a specific match.
  Future<void> updateMatchScore({
    required String matchId,
    required String scoreA,
    required String scoreB,
    required String status,
  }) async {
    await _matchesRef.doc(matchId).update({
      'scoreA': scoreA,
      'scoreB': scoreB,
      'status': status,
    });
  }

  /// Checks if the matches collection is empty and seeds sample matches if so.
  Future<void> autoSeedIfEmpty() async {
    try {
      final snapshot = await _matchesRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        await seedSampleMatches();
      }
    } catch (e) {
      // Gracefully handle initial offline / rules errors
    }
  }

  /// Seeds 6 diverse cricket matches with all 3 statuses and fallback logo test cases.
  Future<void> seedSampleMatches() async {
    final now = DateTime.now();

    final List<Map<String, dynamic>> sampleMatches = [
      {
        'teamA': 'Australia',
        'teamB': 'New Zealand',
        'teamALogoUrl': 'https://flagcdn.com/w160/au.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/nz.png',
        'scoreA': '287/6',
        'scoreB': '112/2',
        'oversA': '42.3',
        'oversB': '22.1',
        'status': 'Live',
        'recentBalls': ['4', '1', '6', 'W', '2', '1'],
        'matchDate': Timestamp.fromDate(now.subtract(const Duration(minutes: 35))),
        'venue': 'Sydney Cricket Ground, Sydney',
      },
      {
        'teamA': 'India',
        'teamB': 'England',
        'teamALogoUrl': 'https://flagcdn.com/w160/in.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/gb-eng.png',
        'scoreA': '224/5',
        'scoreB': '98/2',
        'oversA': '36.4',
        'oversB': '18.2',
        'status': 'Live',
        'recentBalls': ['1', '4', '0', '6', '1', '2'],
        'matchDate': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'venue': 'Melbourne Cricket Ground, Melbourne',
      },
      {
        'teamA': 'Pakistan',
        'teamB': 'South Africa',
        'teamALogoUrl': '', // Empty to test fallback!
        'teamBLogoUrl': '', // Empty to test fallback!
        'scoreA': '0/0',
        'scoreB': '0/0',
        'oversA': '0.0',
        'oversB': '0.0',
        'status': 'Upcoming',
        'recentBalls': <String>[],
        'matchDate': Timestamp.fromDate(now.add(const Duration(hours: 4))),
        'venue': 'Eden Park, Auckland',
      },
      {
        'teamA': 'West Indies',
        'teamB': 'Sri Lanka',
        'teamALogoUrl': 'https://flagcdn.com/w160/jm.png',
        'teamBLogoUrl': '', // One with logo, one empty fallback
        'scoreA': '0/0',
        'scoreB': '0/0',
        'oversA': '0.0',
        'oversB': '0.0',
        'status': 'Upcoming',
        'recentBalls': <String>[],
        'matchDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'venue': 'Kensington Oval, Bridgetown',
      },
      {
        'teamA': 'Bangladesh',
        'teamB': 'Afghanistan',
        'teamALogoUrl': '', // Fallback test
        'teamBLogoUrl': '', // Fallback test
        'scoreA': '265/7',
        'scoreB': '241/10',
        'oversA': '50.0',
        'oversB': '48.2',
        'status': 'Finished',
        'recentBalls': ['1', 'W', '4', '0', '1', 'W'],
        'matchDate': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'venue': 'Sher-e-Bangla Stadium, Dhaka',
      },
      {
        'teamA': 'Gujarat Titans',
        'teamB': 'Chennai Super Kings',
        'teamALogoUrl': 'https://flagcdn.com/w160/in.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/in.png',
        'scoreA': '198/5',
        'scoreB': '201/5',
        'oversA': '20.0',
        'oversB': '19.4',
        'status': 'Finished',
        'recentBalls': ['4', '6', '1', '4', '2', '6'],
        'matchDate': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'venue': 'Narendra Modi Stadium, Ahmedabad',
      },
    ];

    final batch = _firestore.batch();
    for (final match in sampleMatches) {
      final docRef = _matchesRef.doc();
      batch.set(docRef, match);
    }
    await batch.commit();
  }
}
