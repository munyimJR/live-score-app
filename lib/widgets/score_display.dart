import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ScoreDisplay extends StatelessWidget {
  final String teamName;
  final String score;
  final bool isLarge;

  const ScoreDisplay({
    super.key,
    required this.teamName,
    required this.score,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanScore = score.trim().isEmpty ? '-' : score.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cleanScore,
          style: isLarge ? AppTheme.scoreStyleLarge : AppTheme.scoreStyle,
        ),
        if (teamName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            teamName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
