import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'live_indicator.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final cleanStatus = status.trim();

    if (cleanStatus.toLowerCase() == 'live') {
      return const LiveIndicator();
    }

    final bool isFinished = cleanStatus.toLowerCase() == 'finished';
    final Color textColor = isFinished ? AppColors.finishedGreen : AppColors.upcomingGrey;
    final Color bgColor = isFinished ? AppColors.finishedBg : AppColors.upcomingBg;
    final Color borderColor = textColor.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        cleanStatus.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
