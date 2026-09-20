import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class AdminScreen extends StatefulWidget {
  final bool showBottomNav;

  const AdminScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final MatchService _matchService = MatchService();

  String? _selectedMatchId;
  int _teamARuns = 0;
  int _teamAWickets = 0;
  int _teamBRuns = 0;
  int _teamBWickets = 0;
  String _selectedStatus = 'Live';
  final bool _isUpdating = false;

  // Which team is currently batting (true = Team A, false = Team B)
  bool _teamABatting = true;

  // Overs state (balls per over)
  int _oversAWhole = 0;
  int _oversABalls = 0;
  int _oversBWhole = 0;
  int _oversBBalls = 0;

  // Recent balls
  final List<String> _recentBalls = [];

  static const List<String> _ballOptions = [
    '0', '1', '2', '3', '4', '6', 'W', 'Wd', 'Nb',
  ];

  // ── Match selection ──────────────────────────────────────────────────────

  void _onMatchSelected(MatchModel match) {
    setState(() {
      _selectedMatchId = match.id;
      final parsedA = MatchModel.parseScore(match.scoreA);
      final parsedB = MatchModel.parseScore(match.scoreB);
      _teamARuns = parsedA.runs;
      _teamAWickets = parsedA.wickets;
      _teamBRuns = parsedB.runs;
      _teamBWickets = parsedB.wickets;
      _selectedStatus = match.status;

      final oversAParts = _parseOvers(match.oversA);
      _oversAWhole = oversAParts.$1;
      _oversABalls = oversAParts.$2;

      final oversBParts = _parseOvers(match.oversB);
      _oversBWhole = oversBParts.$1;
      _oversBBalls = oversBParts.$2;

      _recentBalls
        ..clear()
        ..addAll(match.recentBalls);
    });
  }

  (int, int) _parseOvers(String overs) {
    if (overs.isEmpty) return (0, 0);
    final parts = overs.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    final balls = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return (whole, balls);
  }

  String _formatOvers(int whole, int balls) => '$whole.$balls';

  // ── Ball tap — the main action ───────────────────────────────────────────

  /// Called when admin taps any ball button.
  /// Updates: recentBalls + score + overs → all written to Firestore at once.
  /// All balls are retained in database (_recentBalls). Visual display handles
  /// showing the latest balls with the rightmost slot free.
  void _onBallTapped(String ball) {
    if (_selectedMatchId == null) return;

    setState(() {
      // 1. Keep all balls in database
      _recentBalls.add(ball);

      final clean = ball.trim().toUpperCase();

      // 2. Update score for batting team
      if (_teamABatting) {
        if (clean == 'W') {
          _teamAWickets = (_teamAWickets + 1).clamp(0, 10);
        } else if (clean == 'WD' || clean == 'NB') {
          _teamARuns += 1; // 1 extra
        } else {
          _teamARuns += int.tryParse(clean) ?? 0;
        }

        // 3. Advance overs (only legal balls — not Wd/Nb)
        if (clean != 'WD' && clean != 'NB') {
          _oversABalls += 1;
          if (_oversABalls >= 6) {
            _oversABalls = 0;
            _oversAWhole += 1;
          }
        }
      } else {
        if (clean == 'W') {
          _teamBWickets = (_teamBWickets + 1).clamp(0, 10);
        } else if (clean == 'WD' || clean == 'NB') {
          _teamBRuns += 1;
        } else {
          _teamBRuns += int.tryParse(clean) ?? 0;
        }

        if (clean != 'WD' && clean != 'NB') {
          _oversBBalls += 1;
          if (_oversBBalls >= 6) {
            _oversBBalls = 0;
            _oversBWhole += 1;
          }
        }
      }
    });

    // 4. Write everything to Firestore immediately
    _pushAllToFirestore();
  }

  void _undoLastBall() {
    if (_recentBalls.isEmpty || _selectedMatchId == null) return;
    final last = _recentBalls.removeLast();
    final clean = last.trim().toUpperCase();

    setState(() {
      if (_teamABatting) {
        if (clean == 'W') {
          _teamAWickets = (_teamAWickets - 1).clamp(0, 10);
        } else if (clean == 'WD' || clean == 'NB') {
          _teamARuns = (_teamARuns - 1).clamp(0, 9999);
        } else {
          _teamARuns = (_teamARuns - (int.tryParse(clean) ?? 0)).clamp(0, 9999);
        }

        if (clean != 'WD' && clean != 'NB') {
          if (_oversABalls > 0) {
            _oversABalls -= 1;
          } else if (_oversAWhole > 0) {
            _oversAWhole -= 1;
            _oversABalls = 5;
          }
        }
      } else {
        if (clean == 'W') {
          _teamBWickets = (_teamBWickets - 1).clamp(0, 10);
        } else if (clean == 'WD' || clean == 'NB') {
          _teamBRuns = (_teamBRuns - 1).clamp(0, 9999);
        } else {
          _teamBRuns = (_teamBRuns - (int.tryParse(clean) ?? 0)).clamp(0, 9999);
        }

        if (clean != 'WD' && clean != 'NB') {
          if (_oversBBalls > 0) {
            _oversBBalls -= 1;
          } else if (_oversBWhole > 0) {
            _oversBWhole -= 1;
            _oversBBalls = 5;
          }
        }
      }
    });

    _pushAllToFirestore();
  }

  void _clearBalls() {
    if (_selectedMatchId == null) return;
    setState(() => _recentBalls.clear());
    _pushAllToFirestore();
  }

  /// Single Firestore write for score + overs + recentBalls + status.
  void _pushAllToFirestore() {
    if (_selectedMatchId == null) return;
    _matchService.updateMatchScore(
      matchId: _selectedMatchId!,
      scoreA: MatchModel.formatScore(_teamARuns, _teamAWickets),
      scoreB: MatchModel.formatScore(_teamBRuns, _teamBWickets),
      status: _selectedStatus,
      oversA: _formatOvers(_oversAWhole, _oversABalls),
      oversB: _formatOvers(_oversBWhole, _oversBBalls),
      recentBalls: List<String>.from(_recentBalls),
    );
  }

  // ── Seed data ────────────────────────────────────────────────────────────

  Future<void> _seedData() async {
    try {
      await _matchService.seedSampleMatches();
      Get.snackbar(
        'Sample Data Seeded',
        'Successfully added sample cricket matches.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceVariant,
        colorText: AppColors.accentGreen,
        icon: const Icon(Icons.sports_cricket, color: AppColors.accentGreen),
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar('Seeding Failed', 'Error: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceVariant,
          colorText: AppColors.liveRed,
          margin: const EdgeInsets.all(16));
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            tooltip: 'Seed sample fixtures',
            icon: const Icon(Icons.cloud_upload_outlined,
                color: AppColors.accentGreen),
            onPressed: _seedData,
          ),
        ],
      ),
      body: StreamBuilder<List<MatchModel>>(
        stream: _matchService.getMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.accentGreen));
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_cricket,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('No matches in database',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: _seedData,
                      icon: const Icon(Icons.add),
                      label: const Text('Seed Sample Matches'),
                    ),
                  ],
                ),
              ),
            );
          }

          MatchModel? currentSelected;
          if (_selectedMatchId != null) {
            try {
              currentSelected =
                  matches.firstWhere((m) => m.id == _selectedMatchId);
            } catch (_) {}
          }

          if (currentSelected == null && matches.isNotEmpty) {
            currentSelected = matches.first;
            _selectedMatchId = currentSelected.id;
            final parsedA = MatchModel.parseScore(currentSelected.scoreA);
            final parsedB = MatchModel.parseScore(currentSelected.scoreB);
            _teamARuns = parsedA.runs;
            _teamAWickets = parsedA.wickets;
            _teamBRuns = parsedB.runs;
            _teamBWickets = parsedB.wickets;
            _selectedStatus = currentSelected.status;

            final oversAParts = _parseOvers(currentSelected.oversA);
            _oversAWhole = oversAParts.$1;
            _oversABalls = oversAParts.$2;

            final oversBParts = _parseOvers(currentSelected.oversB);
            _oversBWhole = oversBParts.$1;
            _oversBBalls = oversBParts.$2;

            _recentBalls
              ..clear()
              ..addAll(currentSelected.recentBalls);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Compact Match & Status Selectors ───────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECT FIXTURE',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _Dropdown(
                            value: _selectedMatchId ?? matches.first.id,
                            items: matches
                                .map((m) => DropdownMenuItem(
                                      value: m.id,
                                      child: Text(
                                        '${m.teamA} vs ${m.teamB}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (id) {
                              if (id != null) {
                                _onMatchSelected(
                                    matches.firstWhere((m) => m.id == id));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STATUS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _Dropdown(
                            value: _selectedStatus,
                            items: ['Upcoming', 'Live', 'Finished']
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: s == 'Live'
                                                  ? AppColors.liveRed
                                                  : s == 'Finished'
                                                      ? AppColors.finishedGreen
                                                      : AppColors.upcomingGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(s,
                                              style: const TextStyle(
                                                  fontSize: 12.5)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (s) {
                              if (s != null) {
                                setState(() => _selectedStatus = s);
                                _pushAllToFirestore();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (currentSelected != null) ...[
                  // ── Live Scoring Panel ────────────────────────────────
                  _LiveScoringPanel(
                    teamA: currentSelected.teamA,
                    teamB: currentSelected.teamB,
                    teamARuns: _teamARuns,
                    teamAWickets: _teamAWickets,
                    teamBRuns: _teamBRuns,
                    teamBWickets: _teamBWickets,
                    oversAWhole: _oversAWhole,
                    oversABalls: _oversABalls,
                    oversBWhole: _oversBWhole,
                    oversBBalls: _oversBBalls,
                    teamABatting: _teamABatting,
                    recentBalls: _recentBalls,
                    ballOptions: _ballOptions,
                    onToggleBatting: () =>
                        setState(() => _teamABatting = !_teamABatting),
                    onBallTapped: _onBallTapped,
                    onUndo: _undoLastBall,
                    onClear: _clearBalls,
                    // Manual score corrections via +/- buttons
                    onRunsAChanged: (delta) {
                      setState(() =>
                          _teamARuns = (_teamARuns + delta).clamp(0, 9999));
                      _pushAllToFirestore();
                    },
                    onWicketsAChanged: (delta) {
                      setState(() => _teamAWickets =
                          (_teamAWickets + delta).clamp(0, 10));
                      _pushAllToFirestore();
                    },
                    onRunsBChanged: (delta) {
                      setState(() =>
                          _teamBRuns = (_teamBRuns + delta).clamp(0, 9999));
                      _pushAllToFirestore();
                    },
                    onWicketsBChanged: (delta) {
                      setState(() => _teamBWickets =
                          (_teamBWickets + delta).clamp(0, 10));
                      _pushAllToFirestore();
                    },
                    onOversAChanged: (whole, balls) {
                      setState(() {
                        _oversAWhole = whole;
                        _oversABalls = balls;
                      });
                      _pushAllToFirestore();
                    },
                    onOversBChanged: (whole, balls) {
                      setState(() {
                        _oversBWhole = whole;
                        _oversBBalls = balls;
                      });
                      _pushAllToFirestore();
                    },
                    isUpdating: _isUpdating,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              currentIndex: 1,
              onTap: (idx) {
                if (idx == 0) Get.back();
              },
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable styled dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceVariant,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentGreen),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Scoring Panel — merged score + balls
// ─────────────────────────────────────────────────────────────────────────────
class _LiveScoringPanel extends StatelessWidget {
  final String teamA;
  final String teamB;
  final int teamARuns;
  final int teamAWickets;
  final int teamBRuns;
  final int teamBWickets;
  final int oversAWhole;
  final int oversABalls;
  final int oversBWhole;
  final int oversBBalls;
  final bool teamABatting;
  final List<String> recentBalls;
  final List<String> ballOptions;

  final VoidCallback onToggleBatting;
  final void Function(String) onBallTapped;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  final void Function(int) onRunsAChanged;
  final void Function(int) onWicketsAChanged;
  final void Function(int) onRunsBChanged;
  final void Function(int) onWicketsBChanged;
  final void Function(int, int) onOversAChanged;
  final void Function(int, int) onOversBChanged;

  final bool isUpdating;

  const _LiveScoringPanel({
    required this.teamA,
    required this.teamB,
    required this.teamARuns,
    required this.teamAWickets,
    required this.teamBRuns,
    required this.teamBWickets,
    required this.oversAWhole,
    required this.oversABalls,
    required this.oversBWhole,
    required this.oversBBalls,
    required this.teamABatting,
    required this.recentBalls,
    required this.ballOptions,
    required this.onToggleBatting,
    required this.onBallTapped,
    required this.onUndo,
    required this.onClear,
    required this.onRunsAChanged,
    required this.onWicketsAChanged,
    required this.onRunsBChanged,
    required this.onWicketsBChanged,
    required this.onOversAChanged,
    required this.onOversBChanged,
    required this.isUpdating,
  });

  Color _bgColorForBall(String ball) {
    switch (ball.trim().toUpperCase()) {
      case 'W':
        return const Color(0xFFD32F2F);
      case '6':
        return const Color(0xFFE68A00);
      case '4':
        return const Color(0xFF1E6B3A);
      case 'WD':
        return const Color(0xFF5B4A8A);
      case 'NB':
        return const Color(0xFF8A6A00);
      default:
        return const Color(0xFF32343E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final battingTeam = teamABatting ? teamA : teamB;
    final battingRuns = teamABatting ? teamARuns : teamBRuns;
    final battingWickets = teamABatting ? teamAWickets : teamBWickets;
    final battingOversW = teamABatting ? oversAWhole : oversBWhole;
    final battingOversB = teamABatting ? oversABalls : oversBBalls;

    // When 6 recentball is full, the leftmost ball remains in database
    // but not in visual, keeping the rightmost slot free for updating new ball.
    final visualBalls = recentBalls.length >= 6
        ? recentBalls.sublist(recentBalls.length - 5)
        : recentBalls;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.liveRed.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Batting team banner + Quick Switch ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF191A22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.liveRed,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'NOW BATTING',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                // Toggle Batting Team button
                GestureDetector(
                  onTap: onToggleBatting,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.liveRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.liveRed.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_horiz_rounded,
                            size: 13, color: AppColors.liveRed),
                        const SizedBox(width: 4),
                        Text(
                          'Switch to ${teamABatting ? teamB : teamA}',
                          style: const TextStyle(
                            color: AppColors.liveRed,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Big Live Score Display ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        battingTeam,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$battingRuns',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            ' / $battingWickets',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Overs bubble
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E202B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2E3142),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'OVERS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$battingOversW.$battingOversB',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Manual quick-adjust row (+1, +4, +6 runs, +W) ───────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ScoreChip(
                    label: '+1 R',
                    color: AppColors.accentGreen,
                    onTap: () {
                      if (teamABatting) {
                        onRunsAChanged(1);
                      } else {
                        onRunsBChanged(1);
                      }
                    },
                  ),
                  const SizedBox(width: 5),
                  _ScoreChip(
                    label: '+4 R',
                    color: const Color(0xFF1E6B3A),
                    onTap: () {
                      if (teamABatting) {
                        onRunsAChanged(4);
                      } else {
                        onRunsBChanged(4);
                      }
                    },
                  ),
                  const SizedBox(width: 5),
                  _ScoreChip(
                    label: '+6 R',
                    color: const Color(0xFFE68A00),
                    onTap: () {
                      if (teamABatting) {
                        onRunsAChanged(6);
                      } else {
                        onRunsBChanged(6);
                      }
                    },
                  ),
                  const SizedBox(width: 5),
                  _ScoreChip(
                    label: '+W',
                    color: AppColors.liveRed,
                    onTap: () {
                      if (teamABatting) {
                        onWicketsAChanged(1);
                      } else {
                        onWicketsBChanged(1);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  // Minus runs button
                  _ScoreChip(
                    label: '-1 R',
                    color: const Color(0xFF2E3040),
                    textColor: AppColors.textSecondary,
                    onTap: () {
                      if (teamABatting) {
                        onRunsAChanged(-1);
                      } else {
                        onRunsBChanged(-1);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),
          const Divider(color: Color(0xFF22232D), height: 1),

          // ── Recent Balls of This Over ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('THIS',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0)),
                    Text('OVER',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(width: 8),
                // 6 ball slots
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(6, (i) {
                        final has = i < visualBalls.length;
                        final isNext = i == visualBalls.length;
                        if (!has) {
                          return Container(
                            width: 27,
                            height: 27,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isNext
                                  ? const Color(0xFF222430)
                                  : const Color(0xFF1C1D24),
                              border: Border.all(
                                  color: isNext
                                      ? AppColors.accentGreen
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFF2E3040),
                                  width: isNext ? 1.4 : 1),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: isNext ? 6 : 5,
                              height: isNext ? 6 : 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isNext
                                    ? AppColors.accentGreen
                                    : const Color(0xFF353749),
                              ),
                            ),
                          );
                        }
                        final ball = visualBalls[i].trim().toUpperCase();
                        final bg = _bgColorForBall(ball);
                        return Container(
                          width: 27,
                          height: 27,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bg,
                            border: Border.all(color: bg, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                  color: bg.withValues(alpha: 0.35),
                                  blurRadius: 4)
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ball,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ball.length > 1 ? 8 : 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // Undo / clear
                if (recentBalls.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onUndo,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E24),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.backspace_outlined,
                          size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1E24),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.clear_all_rounded,
                          size: 14, color: AppColors.liveRed),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Ball Buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth =
                    ((constraints.maxWidth - (6 * 4)) / 5).clamp(42.0, 58.0);
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ballOptions.map((option) {
                    final bg = _bgColorForBall(option);
                    return GestureDetector(
                      onTap: () => onBallTapped(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 110),
                        width: buttonWidth,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: bg,
                            width: 1.1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          option,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: option.length > 1 ? 10.5 : 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          if (recentBalls.length >= 6)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 13, color: AppColors.accentGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${recentBalls.length} balls total • Last 5 shown (slot 6 ready)',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Score Adjustment Chip
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ScoreChip({
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
