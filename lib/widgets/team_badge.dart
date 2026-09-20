import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'team_logo.dart';

class TeamBadge extends StatelessWidget {
  final String teamName;
  final String logoUrl;
  final double logoSize;

  const TeamBadge({
    super.key,
    required this.teamName,
    required this.logoUrl,
    this.logoSize = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamLogo(
          logoUrl: logoUrl,
          teamName: teamName,
          size: logoSize,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 88,
          child: Text(
            teamName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
