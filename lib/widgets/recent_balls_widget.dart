import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RecentBallsWidget extends StatelessWidget {
  final List<String> balls;

  const RecentBallsWidget({
    super.key,
    required this.balls,
  });

  @override
  Widget build(BuildContext context) {
    if (balls.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2B2C35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Recent Balls',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: balls.map((ball) => _buildBallCircle(ball)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBallCircle(String ball) {
    final clean = ball.trim().toUpperCase();

    Color bgColor = const Color(0xFF32343E);
    Color textColor = Colors.white;

    if (clean == 'W') {
      // Wicket - Red
      bgColor = const Color(0xFFD32F2F);
      textColor = Colors.white;
    } else if (clean == '6') {
      // Six - Vibrant Amber/Orange
      bgColor = const Color(0xFFE68A00);
      textColor = Colors.white;
    } else if (clean == '4') {
      // Four - Slightly accented or grey
      bgColor = const Color(0xFF383B46);
      textColor = Colors.white;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      alignment: Alignment.center,
      child: Text(
        clean,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
