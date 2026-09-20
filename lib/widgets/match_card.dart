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

    // Default recent balls for Live matches if not explicitly set
    final List<String> balls = match.recentBalls.isNotEmpty
        ? match.recentBalls
        : (isLive ? const ['4', '1', '6', 'W', '2', '1'] : const []);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLive
              ? AppColors.liveRed.withValues(alpha: 0.35)
              : const Color(0xFF26262F),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Header: Status chip & Match date/time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusChip(status: match.status),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormatter.formatCardDate(match.matchDate),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Match Row: [Team A]  [Score & Overs]  [Team B]
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team A Logo + Name
                    TeamBadge(
                      teamName: match.teamA,
                      logoUrl: match.teamALogoUrl,
                      logoSize: 52,
                    ),

                    // Center Primary Score & Overs
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            isUpcoming ? 'VS' : scoreAFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!isUpcoming)
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$oversA ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Overs',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Text(
                              'Starts Soon',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Team B Logo + Name
                    TeamBadge(
                      teamName: match.teamB,
                      logoUrl: match.teamBLogoUrl,
                      logoSize: 52,
                    ),
                  ],
                ),

                // Secondary Chasing Score (Bright Green)
                if (!isUpcoming) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$scoreBFormatted   •   $oversB OV',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],

                // Recent Balls Container (if live or has balls)
                if (balls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  RecentBallsWidget(balls: balls),
                ],

                const SizedBox(height: 14),

                // Footer: Venue
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13.5,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.venue,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
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
