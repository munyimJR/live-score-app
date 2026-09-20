import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/match_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/status_filter_chips.dart';
import 'admin_screen.dart';
import 'match_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchService _matchService = MatchService();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  void _onNavTap(int index) {
    if (index == 1) {
      Get.to(() => const AdminScreen());
    }
  }

  List<MatchModel> _filterMatches(List<MatchModel> allMatches) {
    return allMatches.where((match) {
      // 1. Status filter
      if (_selectedStatus != 'All' &&
          match.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      // 2. Search filter (case-insensitive substring match on teamA or teamB)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTeamA = match.teamA.toLowerCase().contains(query);
        final matchesTeamB = match.teamB.toLowerCase().contains(query);
        if (!matchesTeamA && !matchesTeamB) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accentGreenMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sports_cricket,
                color: AppColors.accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('CRICKET LIVE'),
          ],
        ),
      ),
      body: StreamBuilder<List<MatchModel>>(
        stream: _matchService.getMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.liveRed, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load matches: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            );
          }

          final allMatches = snapshot.data ?? [];
          final filteredMatches = _filterMatches(allMatches);

          return Column(
            children: [
              // Search and Filter Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    SearchBarWidget(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    StatusFilterChips(
                      selectedStatus: _selectedStatus,
                      onSelected: (status) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Match Count & List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SectionHeader(
                  title: _selectedStatus == 'All'
                      ? 'All Fixtures'
                      : '$_selectedStatus Matches',
                  subtitle: '${filteredMatches.length} matches found',
                ),
              ),

              // Match Cards List
              Expanded(
                child: filteredMatches.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          final match = filteredMatches[index];
                          return MatchCard(
                            match: match,
                            onTap: () {
                              Get.to(() => MatchDetailsScreen(matchId: match.id));
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_cricket_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matches found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search query or filter chip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
