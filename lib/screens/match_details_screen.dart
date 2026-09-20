import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/team_row.dart';

class MatchDetailsScreen extends StatelessWidget {
  final String matchId;
  final MatchService _matchService = MatchService();

  MatchDetailsScreen({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Match Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: match.status.toLowerCase() == 'live'
                          ? AppColors.liveRed.withValues(alpha: 0.4)
                          : AppColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Team A Prominent Row
                      TeamRow(
                        teamName: match.teamA,
                        logoUrl: match.teamALogoUrl,
                        score: match.scoreA,
                        isLarge: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: AppColors.cardBorder, height: 1),
                      ),

                      // Team B Prominent Row
                      TeamRow(
                        teamName: match.teamB,
                        logoUrl: match.teamBLogoUrl,
                        score: match.scoreB,
                        isLarge: true,
                      ),
                    ],
                  ),
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

                // Live Updates Note
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
