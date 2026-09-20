import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';

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

  /// Updates score, overs, recent balls, and status for a specific match.
  Future<void> updateMatchScore({
    required String matchId,
    required String scoreA,
    required String scoreB,
    required String status,
    String oversA = '',
    String oversB = '',
    List<String> recentBalls = const [],
  }) async {
    await _matchesRef.doc(matchId).update({
      'scoreA': scoreA,
      'scoreB': scoreB,
      'status': status,
      'oversA': oversA,
      'oversB': oversB,
      'recentBalls': recentBalls,
    });
  }

  /// Immediately writes only the recentBalls field — called on every ball tap
  /// so listeners (StreamBuilder) get the update without pressing UPDATE SCORE.
  Future<void> updateRecentBalls({
    required String matchId,
    required List<String> recentBalls,
  }) async {
    await _matchesRef.doc(matchId).update({
      'recentBalls': recentBalls,
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

  /// Provides fallback standard playing 11 for known cricket teams.
  static List<PlayerModel> getDefaultPlayingEleven(String teamName) {
    final clean = teamName.toLowerCase().trim();

    if (clean.contains('aus')) {
      return const [
        PlayerModel(name: 'David Warner', role: 'Batter'),
        PlayerModel(name: 'Travis Head', role: 'Batter'),
        PlayerModel(name: 'Mitchell Marsh', role: 'All-Rounder'),
        PlayerModel(name: 'Steven Smith', role: 'Batter'),
        PlayerModel(name: 'Marnus Labuschagne', role: 'Batter'),
        PlayerModel(name: 'Glenn Maxwell', role: 'All-Rounder'),
        PlayerModel(name: 'Josh Inglis', role: 'WK-Batter', isWicketKeeper: true),
        PlayerModel(name: 'Pat Cummins', role: 'Bowler', isCaptain: true),
        PlayerModel(name: 'Mitchell Starc', role: 'Bowler'),
        PlayerModel(name: 'Adam Zampa', role: 'Bowler'),
        PlayerModel(name: 'Josh Hazlewood', role: 'Bowler'),
      ];
    } else if (clean.contains('zealand') || clean.contains('nz')) {
      return const [
        PlayerModel(name: 'Devon Conway', role: 'Batter'),
        PlayerModel(name: 'Will Young', role: 'Batter'),
        PlayerModel(name: 'Rachin Ravindra', role: 'All-Rounder'),
        PlayerModel(name: 'Kane Williamson', role: 'Batter', isCaptain: true),
        PlayerModel(name: 'Daryl Mitchell', role: 'All-Rounder'),
        PlayerModel(name: 'Tom Latham', role: 'WK-Batter', isWicketKeeper: true),
        PlayerModel(name: 'Glenn Phillips', role: 'All-Rounder'),
        PlayerModel(name: 'Mitchell Santner', role: 'All-Rounder'),
        PlayerModel(name: 'Matt Henry', role: 'Bowler'),
        PlayerModel(name: 'Tim Southee', role: 'Bowler'),
        PlayerModel(name: 'Trent Boult', role: 'Bowler'),
      ];
    } else if (clean.contains('ind')) {
      return const [
        PlayerModel(name: 'Rohit Sharma', role: 'Batter', isCaptain: true),
        PlayerModel(name: 'Shubman Gill', role: 'Batter'),
        PlayerModel(name: 'Virat Kohli', role: 'Batter'),
        PlayerModel(name: 'Shreyas Iyer', role: 'Batter'),
        PlayerModel(name: 'KL Rahul', role: 'WK-Batter', isWicketKeeper: true),
        PlayerModel(name: 'Hardik Pandya', role: 'All-Rounder'),
        PlayerModel(name: 'Ravindra Jadeja', role: 'All-Rounder'),
        PlayerModel(name: 'Kuldeep Yadav', role: 'Bowler'),
        PlayerModel(name: 'Jasprit Bumrah', role: 'Bowler'),
        PlayerModel(name: 'Mohammed Shami', role: 'Bowler'),
        PlayerModel(name: 'Mohammed Siraj', role: 'Bowler'),
      ];
    } else if (clean.contains('eng')) {
      return const [
        PlayerModel(name: 'Jonny Bairstow', role: 'Batter'),
        PlayerModel(name: 'Dawid Malan', role: 'Batter'),
        PlayerModel(name: 'Joe Root', role: 'Batter'),
        PlayerModel(name: 'Ben Stokes', role: 'All-Rounder'),
        PlayerModel(name: 'Harry Brook', role: 'Batter'),
        PlayerModel(name: 'Jos Buttler', role: 'WK-Batter', isCaptain: true, isWicketKeeper: true),
        PlayerModel(name: 'Liam Livingstone', role: 'All-Rounder'),
        PlayerModel(name: 'Chris Woakes', role: 'All-Rounder'),
        PlayerModel(name: 'Adil Rashid', role: 'Bowler'),
        PlayerModel(name: 'Mark Wood', role: 'Bowler'),
        PlayerModel(name: 'Reece Topley', role: 'Bowler'),
      ];
    } else if (clean.contains('pak')) {
      return const [
        PlayerModel(name: 'Abdullah Shafique', role: 'Batter'),
        PlayerModel(name: 'Fakhar Zaman', role: 'Batter'),
        PlayerModel(name: 'Babar Azam', role: 'Batter', isCaptain: true),
        PlayerModel(name: 'Mohammad Rizwan', role: 'WK-Batter', isWicketKeeper: true),
        PlayerModel(name: 'Saud Shakeel', role: 'Batter'),
        PlayerModel(name: 'Iftikhar Ahmed', role: 'All-Rounder'),
        PlayerModel(name: 'Shadab Khan', role: 'All-Rounder'),
        PlayerModel(name: 'Mohammad Nawaz', role: 'All-Rounder'),
        PlayerModel(name: 'Shaheen Afridi', role: 'Bowler'),
        PlayerModel(name: 'Haris Rauf', role: 'Bowler'),
        PlayerModel(name: 'Naseem Shah', role: 'Bowler'),
      ];
    } else if (clean.contains('africa')) {
      return const [
        PlayerModel(name: 'Quinton de Kock', role: 'WK-Batter', isWicketKeeper: true),
        PlayerModel(name: 'Temba Bavuma', role: 'Batter', isCaptain: true),
        PlayerModel(name: 'Rassie van der Dussen', role: 'Batter'),
        PlayerModel(name: 'Aiden Markram', role: 'All-Rounder'),
        PlayerModel(name: 'Heinrich Klaasen', role: 'Batter'),
        PlayerModel(name: 'David Miller', role: 'Batter'),
        PlayerModel(name: 'Marco Jansen', role: 'All-Rounder'),
        PlayerModel(name: 'Gerald Coetzee', role: 'Bowler'),
        PlayerModel(name: 'Keshav Maharaj', role: 'Bowler'),
        PlayerModel(name: 'Kagiso Rabada', role: 'Bowler'),
        PlayerModel(name: 'Lungi Ngidi', role: 'Bowler'),
      ];
    }

    // Default template for any other team
    return List.generate(11, (i) {
      if (i == 0) return PlayerModel(name: '$teamName Opener 1', role: 'Batter');
      if (i == 1) return PlayerModel(name: '$teamName Opener 2', role: 'Batter');
      if (i == 2) return PlayerModel(name: '$teamName Captain', role: 'Batter', isCaptain: true);
      if (i == 3) return PlayerModel(name: '$teamName Batter', role: 'Batter');
      if (i == 4) return PlayerModel(name: '$teamName Keeper', role: 'WK-Batter', isWicketKeeper: true);
      if (i == 5) return PlayerModel(name: '$teamName All-Rounder 1', role: 'All-Rounder');
      if (i == 6) return PlayerModel(name: '$teamName All-Rounder 2', role: 'All-Rounder');
      if (i == 7) return PlayerModel(name: '$teamName Spinner', role: 'Bowler');
      if (i == 8) return PlayerModel(name: '$teamName Pacer 1', role: 'Bowler');
      if (i == 9) return PlayerModel(name: '$teamName Pacer 2', role: 'Bowler');
      return PlayerModel(name: '$teamName Strike Bowler', role: 'Bowler');
    });
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
        'teamAPlayers': getDefaultPlayingEleven('Australia').map((p) => p.toMap()).toList(),
        'teamBPlayers': getDefaultPlayingEleven('New Zealand').map((p) => p.toMap()).toList(),
        'matchDate': Timestamp.fromDate(now.subtract(const Duration(minutes: 35))),
        'venue': 'Sydney Cricket Ground, Sydney',
      },
      {
        'teamA': 'India',
        'teamB': 'England',
        'teamALogoUrl': 'https://flagcdn.com/w160/in.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/gb.png',
        'scoreA': '224/5',
        'scoreB': '98/2',
        'oversA': '36.4',
        'oversB': '18.2',
        'status': 'Live',
        'recentBalls': ['1', '4', '0', '6', '1', '2'],
        'teamAPlayers': getDefaultPlayingEleven('India').map((p) => p.toMap()).toList(),
        'teamBPlayers': getDefaultPlayingEleven('England').map((p) => p.toMap()).toList(),
        'matchDate': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'venue': 'Melbourne Cricket Ground, Melbourne',
      },
      {
        'teamA': 'Pakistan',
        'teamB': 'South Africa',
        'teamALogoUrl': 'https://flagcdn.com/w160/pk.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/za.png',
        'scoreA': '0/0',
        'scoreB': '0/0',
        'oversA': '0.0',
        'oversB': '0.0',
        'status': 'Upcoming',
        'recentBalls': <String>[],
        'teamAPlayers': getDefaultPlayingEleven('Pakistan').map((p) => p.toMap()).toList(),
        'teamBPlayers': getDefaultPlayingEleven('South Africa').map((p) => p.toMap()).toList(),
        'matchDate': Timestamp.fromDate(now.add(const Duration(hours: 4))),
        'venue': 'Eden Park, Auckland',
      },
      {
        'teamA': 'West Indies',
        'teamB': 'Sri Lanka',
        'teamALogoUrl': 'https://flagcdn.com/w160/jm.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/lk.png',
        'scoreA': '0/0',
        'scoreB': '0/0',
        'oversA': '0.0',
        'oversB': '0.0',
        'status': 'Upcoming',
        'recentBalls': <String>[],
        'teamAPlayers': getDefaultPlayingEleven('West Indies').map((p) => p.toMap()).toList(),
        'teamBPlayers': getDefaultPlayingEleven('Sri Lanka').map((p) => p.toMap()).toList(),
        'matchDate': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'venue': 'Kensington Oval, Bridgetown',
      },
      {
        'teamA': 'Bangladesh',
        'teamB': 'Afghanistan',
        'teamALogoUrl': 'https://flagcdn.com/w160/bd.png',
        'teamBLogoUrl': 'https://flagcdn.com/w160/af.png',
        'scoreA': '265/7',
        'scoreB': '241/10',
        'oversA': '50.0',
        'oversB': '48.2',
        'status': 'Finished',
        'recentBalls': ['1', 'W', '4', '0', '1', 'W'],
        'teamAPlayers': getDefaultPlayingEleven('Bangladesh').map((p) => p.toMap()).toList(),
        'teamBPlayers': getDefaultPlayingEleven('Afghanistan').map((p) => p.toMap()).toList(),
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
        'teamAPlayers': getDefaultPlayingEleven('Gujarat Titans').map((p) => p.toMap()).toList(),
        'teamBPlayers': getDefaultPlayingEleven('Chennai Super Kings').map((p) => p.toMap()).toList(),
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
