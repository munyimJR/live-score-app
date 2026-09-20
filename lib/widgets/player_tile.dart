import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../theme/app_colors.dart';

class PlayerTile extends StatelessWidget {
  final int index;
  final PlayerModel player;

  const PlayerTile({
    super.key,
    required this.index,
    required this.player,
  });

  Color _getRoleColor(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('all') || lower.contains('rounder')) {
      return AppColors.accentGreen;
    } else if (lower.contains('bowl')) {
      return const Color(0xFF64B5F6); // Soft blue
    } else if (lower.contains('wk') || lower.contains('keeper')) {
      return const Color(0xFFBA68C8); // Soft purple
    } else {
      return const Color(0xFFFFB74D); // Soft amber for Batter
    }
  }

  IconData _getRoleIcon(String role) {
    final lower = role.toLowerCase();
    if (lower.contains('bowl')) {
      return Icons.sports_baseball_outlined;
    } else if (lower.contains('wk') || lower.contains('keeper')) {
      return Icons.front_hand_outlined;
    } else if (lower.contains('all') || lower.contains('rounder')) {
      return Icons.all_inclusive_rounded;
    } else {
      return Icons.sports_cricket;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(player.role);
    final roleIcon = _getRoleIcon(player.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF191A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF282932),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Player Number / Order Badge
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF242630),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player Name & Badges
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (player.isCaptain) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreenMuted,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accentGreen, width: 0.8),
                    ),
                    child: const Text(
                      'C',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                if (player.isWicketKeeper) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0x28BA68C8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBA68C8), width: 0.8),
                    ),
                    child: const Text(
                      'WK',
                      style: TextStyle(
                        color: Color(0xFFBA68C8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Role Badge with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: roleColor.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 12, color: roleColor),
                const SizedBox(width: 4),
                Text(
                  player.role,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
