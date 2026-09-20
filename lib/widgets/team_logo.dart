import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TeamLogo extends StatelessWidget {
  final String logoUrl;
  final double size;

  const TeamLogo({
    super.key,
    required this.logoUrl,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValidUrl = logoUrl.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasValidUrl
            ? Image.network(
                logoUrl.trim(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        Icons.sports_cricket,
        size: size * 0.55,
        color: AppColors.accentGreen,
      ),
    );
  }
}
