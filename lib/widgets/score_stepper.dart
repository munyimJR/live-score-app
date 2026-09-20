import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScoreStepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool isWickets;

  const ScoreStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.isWickets = false,
  });

  void _decrement() {
    if (value > min) {
      onChanged(value - 1);
    }
  }

  void _increment([int step = 1]) {
    final next = value + step;
    if (next <= max) {
      onChanged(next);
    } else {
      onChanged(max);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isWickets)
                Row(
                  children: [
                    _buildQuickAddBadge('+4', () => _increment(4)),
                    const SizedBox(width: 6),
                    _buildQuickAddBadge('+6', () => _increment(6)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildButton(
                icon: Icons.remove,
                onPressed: value > min ? _decrement : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _buildButton(
                icon: Icons.add,
                onPressed: value < max ? () => _increment(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddBadge(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.accentGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final bool isEnabled = onPressed != null;

    return Material(
      color: isEnabled ? AppColors.surface : AppColors.surface.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isEnabled ? AppColors.cardBorder : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 38,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}
