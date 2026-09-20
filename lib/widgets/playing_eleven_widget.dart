import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../theme/app_colors.dart';
import 'player_tile.dart';
import 'team_logo.dart';

class PlayingElevenWidget extends StatefulWidget {
  final String teamAName;
  final String teamBName;
  final String teamALogoUrl;
  final String teamBLogoUrl;
  final List<PlayerModel> teamAPlayers;
  final List<PlayerModel> teamBPlayers;

  const PlayingElevenWidget({
    super.key,
    required this.teamAName,
    required this.teamBName,
    required this.teamALogoUrl,
    required this.teamBLogoUrl,
    required this.teamAPlayers,
    required this.teamBPlayers,
  });

  @override
  State<PlayingElevenWidget> createState() => _PlayingElevenWidgetState();
}

class _PlayingElevenWidgetState extends State<PlayingElevenWidget> {
  int _selectedTeamIndex = 0; // 0 for Team A, 1 for Team B

  @override
  Widget build(BuildContext context) {
    final isTeamA = _selectedTeamIndex == 0;
    final currentPlayers = isTeamA ? widget.teamAPlayers : widget.teamBPlayers;
    final currentTeamName = isTeamA ? widget.teamAName : widget.teamBName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Switcher Tabs (Team A vs Team B)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTeamTab(
                    index: 0,
                    teamName: widget.teamAName,
                    logoUrl: widget.teamALogoUrl,
                    isSelected: _selectedTeamIndex == 0,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildTeamTab(
                    index: 1,
                    teamName: widget.teamBName,
                    logoUrl: widget.teamBLogoUrl,
                    isSelected: _selectedTeamIndex == 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Header with count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentTeamName Lineup',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${currentPlayers.length} Players',
                style: const TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Player List
          if (currentPlayers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                'Playing 11 to be announced at toss',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentPlayers.length,
              itemBuilder: (context, index) {
                final player = currentPlayers[index];
                return PlayerTile(
                  index: index + 1,
                  player: player,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTeamTab({
    required int index,
    required String teamName,
    required String logoUrl,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTeamIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TeamLogo(
              logoUrl: logoUrl,
              teamName: teamName,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                teamName,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
