import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'score_display.dart';
import 'team_logo.dart';

class TeamRow extends StatelessWidget {
  final String teamName;
  final String logoUrl;
  final String score;
  final bool isLarge;

  const TeamRow({
    super.key,
    required this.teamName,
    required this.logoUrl,
    required this.score,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamLogo(
          logoUrl: logoUrl,
          teamName: teamName,
          size: isLarge ? 48.0 : 38.0,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: isLarge ? 17 : 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        ScoreDisplay(
          teamName: '',
          score: score,
          isLarge: isLarge,
        ),
      ],
    );
  }
}
