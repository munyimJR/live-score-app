import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/score_stepper.dart';
import '../widgets/section_header.dart';

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
  bool _isUpdating = false;

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
    });
  }

  Future<void> _updateScore(MatchModel selectedMatch) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final newScoreA = MatchModel.formatScore(_teamARuns, _teamAWickets);
      final newScoreB = MatchModel.formatScore(_teamBRuns, _teamBWickets);

      await _matchService.updateMatchScore(
        matchId: selectedMatch.id,
        scoreA: newScoreA,
        scoreB: newScoreB,
        status: _selectedStatus,
      );

      Get.snackbar(
        'Score Updated',
        '${selectedMatch.teamA} ($newScoreA) vs ${selectedMatch.teamB} ($newScoreB) • $_selectedStatus',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceVariant,
        colorText: AppColors.accentGreen,
        icon: const Icon(Icons.check_circle, color: AppColors.accentGreen),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        'Error updating score: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceVariant,
        colorText: AppColors.liveRed,
        icon: const Icon(Icons.error, color: AppColors.liveRed),
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _seedData() async {
    try {
      await _matchService.seedSampleMatches();
      Get.snackbar(
        'Sample Data Seeded',
        'Successfully added 6 sample cricket matches with live scores.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceVariant,
        colorText: AppColors.accentGreen,
        icon: const Icon(Icons.sports_cricket, color: AppColors.accentGreen),
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Seeding Failed',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surfaceVariant,
        colorText: AppColors.liveRed,
        icon: const Icon(Icons.error, color: AppColors.liveRed),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            tooltip: 'Seed sample fixtures',
            icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.accentGreen),
            onPressed: _seedData,
          ),
        ],
      ),
      body: StreamBuilder<List<MatchModel>>(
        stream: _matchService.getMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            );
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_cricket, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'No matches in database',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap below to seed initial sample matches.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

          // Ensure selected match exists in the list
          MatchModel? currentSelected;
          if (_selectedMatchId != null) {
            try {
              currentSelected = matches.firstWhere((m) => m.id == _selectedMatchId);
            } catch (_) {
              currentSelected = null;
            }
          }

          // Default to first match if none selected
          if (currentSelected == null && matches.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedMatchId == null) {
                _onMatchSelected(matches.first);
              }
            });
            currentSelected = matches.first;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match Selector
                const SectionHeader(
                  title: 'Select Match',
                  subtitle: 'Choose a fixture to manage scores',
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMatchId ?? matches.first.id,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceVariant,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentGreen),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: matches.map((match) {
                        return DropdownMenuItem<String>(
                          value: match.id,
                          child: Text(
                            '${match.teamA} vs ${match.teamB} (${match.status})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newId) {
                        if (newId != null) {
                          final selected = matches.firstWhere((m) => m.id == newId);
                          _onMatchSelected(selected);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (currentSelected != null) ...[
                  // Match Status Selector
                  const SectionHeader(
                    title: 'Match Status',
                    subtitle: 'Current progress of the match',
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceVariant,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.accentGreen),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['Upcoming', 'Live', 'Finished'].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: status == 'Live'
                                        ? AppColors.liveRed
                                        : (status == 'Finished'
                                            ? AppColors.finishedGreen
                                            : AppColors.upcomingGrey),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null) {
                            setState(() {
                              _selectedStatus = newStatus;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Team A Steppers
                  SectionHeader(
                    title: currentSelected.teamA,
                    subtitle: 'Innings score & dismissals',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ScoreStepper(
                          label: '${currentSelected.teamA} Runs',
                          value: _teamARuns,
                          onChanged: (val) => setState(() => _teamARuns = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ScoreStepper(
                          label: 'Wickets',
                          value: _teamAWickets,
                          max: 10,
                          isWickets: true,
                          onChanged: (val) => setState(() => _teamAWickets = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Team B Steppers
                  SectionHeader(
                    title: currentSelected.teamB,
                    subtitle: 'Innings score & dismissals',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ScoreStepper(
                          label: '${currentSelected.teamB} Runs',
                          value: _teamBRuns,
                          onChanged: (val) => setState(() => _teamBRuns = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ScoreStepper(
                          label: 'Wickets',
                          value: _teamBWickets,
                          max: 10,
                          isWickets: true,
                          onChanged: (val) => setState(() => _teamBWickets = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Update Score Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isUpdating ? null : () => _updateScore(currentSelected!),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'UPDATE SCORE',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
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
                if (idx == 0) {
                  Get.back();
                }
              },
            )
          : null,
    );
  }
}
