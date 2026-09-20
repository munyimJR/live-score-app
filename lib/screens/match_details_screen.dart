import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/playing_eleven_widget.dart';
import '../widgets/recent_balls_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/team_badge.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String matchId;
  final MatchService _matchService = MatchService();

  MatchDetailsScreen({
    super.key,
    required this.matchId,
  });

  String _formatScore(String score) {
    final clean = score.trim();
    if (clean.contains('/')) {
      final parts = clean.split('/');
      return '${parts[0].trim()} / ${parts[1].trim()}';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: Get.back,
        ),
      ),
      body: StreamBuilder<MatchModel?>(
        stream: _matchService.getMatchStream(matchId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading match details: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.liveRed),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            );
          }

          final match = snapshot.data;
          if (match == null) {
            return const Center(
              child: Text(
                'Match not found or removed',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final isLive = match.status.toLowerCase() == 'live';
          final isUpcoming = match.status.toLowerCase() == 'upcoming';

          final scoreAFormatted = _formatScore(match.scoreA);
          final scoreBFormatted = _formatScore(match.scoreB);

          final oversA = match.oversA.isNotEmpty ? match.oversA : (isUpcoming ? '0.0' : '50.0');
          final oversB = match.oversB.isNotEmpty ? match.oversB : (isUpcoming ? '0.0' : '20.0');

          // Only show real balls from Firestore — no hardcoded fallback
          final List<String> balls = match.recentBalls;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Scorecard Card (Matching the new visual design)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isLive
                          ? AppColors.liveRed.withValues(alpha: 0.4)
                          : const Color(0xFF26262F),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Status & Date row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusChip(status: match.status),
                          Text(
                            DateFormatter.formatCardDate(match.matchDate),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Matchup Row: [Team A]  [Score & Overs]  [Team B]
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TeamBadge(
                            teamName: match.teamA,
                            logoUrl: match.teamALogoUrl,
                            logoSize: 44,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isUpcoming) ...[
                                  const Text(
                                    'VS',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Starts Soon',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    scoreAFormatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$oversA ',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'Overs',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1D26),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF282A38),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      (match.scoreB.trim() == '0/0' &&
                                              (match.oversB.trim() == '0.0' ||
                                                  match.oversB.isEmpty))
                                          ? '${match.teamB}: Yet to bat'
                                          : '$scoreBFormatted  •  $oversB ov',
                                      style: TextStyle(
                                        color: (match.scoreB.trim() == '0/0' &&
                                                (match.oversB.trim() == '0.0' ||
                                                    match.oversB.isEmpty))
                                            ? AppColors.textMuted
                                            : const Color(0xFF00E676),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          TeamBadge(
                            teamName: match.teamB,
                            logoUrl: match.teamBLogoUrl,
                            logoSize: 44,
                          ),
                        ],
                      ),

                      // Recent Balls Widget — always show for Live matches
                      if (isLive || balls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        RecentBallsWidget(
                          balls: balls,
                          showEmptySlots: isLive,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Playing XI Section Header
                const SectionHeader(
                  title: 'Playing XI',
                  subtitle: 'Official team lineups & player roles',
                ),
                const SizedBox(height: 8),

                // Playing XI Interactive Component
                PlayingElevenWidget(
                  teamAName: match.teamA,
                  teamBName: match.teamB,
                  teamALogoUrl: match.teamALogoUrl,
                  teamBLogoUrl: match.teamBLogoUrl,
                  teamAPlayers: match.teamAPlayers.isNotEmpty
                      ? match.teamAPlayers
                      : MatchService.getDefaultPlayingEleven(match.teamA),
                  teamBPlayers: match.teamBPlayers.isNotEmpty
                      ? match.teamBPlayers
                      : MatchService.getDefaultPlayingEleven(match.teamB),
                ),
                const SizedBox(height: 24),

                // Match Info Section Header
                const SectionHeader(
                  title: 'Match Information',
                  subtitle: 'Official fixture & stadium details',
                ),
                const SizedBox(height: 8),

                // Venue & Schedule Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Venue',
                        value: match.venue,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: AppColors.cardBorder, height: 1),
                      ),
                      _buildInfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Scheduled Time',
                        value: DateFormatter.formatFull(match.matchDate),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: AppColors.cardBorder, height: 1),
                      ),
                      _buildInfoRow(
                        icon: Icons.info_outline,
                        label: 'Match Status',
                        value: match.status,
                        isStatus: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Real-time Indicator Note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Scores update automatically in real-time',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isStatus = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentGreen, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isStatus ? AppColors.accentGreen : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
