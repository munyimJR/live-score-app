import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import 'recent_balls_widget.dart';
import 'status_chip.dart';
import 'team_badge.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
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
    final isLive = match.status.toLowerCase() == 'live';
    final isUpcoming = match.status.toLowerCase() == 'upcoming';

    final scoreAFormatted = _formatScore(match.scoreA);
    final scoreBFormatted = _formatScore(match.scoreB);

    final oversA = match.oversA.isNotEmpty ? match.oversA : (isUpcoming ? '0.0' : '50.0');
    final oversB = match.oversB.isNotEmpty ? match.oversB : (isUpcoming ? '0.0' : '20.0');

    // Only show real balls from Firestore — no hardcoded fallback
    final List<String> balls = match.recentBalls;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? AppColors.liveRed.withValues(alpha: 0.35)
              : const Color(0xFF26262F),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                // Header: Status chip & Match date/time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusChip(status: match.status),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 11.5,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatCardDate(match.matchDate),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Match Row: [Team A]  [Score & Overs]  [Team B]
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Team A Logo + Name
                    TeamBadge(
                      teamName: match.teamA,
                      logoUrl: match.teamALogoUrl,
                      logoSize: 40,
                    ),

                    // Center Primary Score & Overs
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUpcoming) ...[
                            const Text(
                              'VS',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Starts Soon',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            Text(
                              scoreAFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$oversA Overs',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
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
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Team B Logo + Name
                    TeamBadge(
                      teamName: match.teamB,
                      logoUrl: match.teamBLogoUrl,
                      logoSize: 40,
                    ),
                  ],
                ),

                // Recent Balls: always show for Live, only when data exists for Finished
                if (isLive || balls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  RecentBallsWidget(
                    balls: balls,
                    showEmptySlots: isLive,
                  ),
                ],

                const SizedBox(height: 8),

                // Footer: Venue
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 11.5,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.venue,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
