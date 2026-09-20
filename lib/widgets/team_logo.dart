import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TeamLogo extends StatelessWidget {
  final String logoUrl;
  final String? teamName;
  final double size;

  const TeamLogo({
    super.key,
    required this.logoUrl,
    this.teamName,
    this.size = 38.0,
  });

  static const Map<String, String> _knownTeamFlags = {
    'australia': 'https://flagcdn.com/w160/au.png',
    'aus': 'https://flagcdn.com/w160/au.png',
    'new zealand': 'https://flagcdn.com/w160/nz.png',
    'nz': 'https://flagcdn.com/w160/nz.png',
    'india': 'https://flagcdn.com/w160/in.png',
    'ind': 'https://flagcdn.com/w160/in.png',
    'england': 'https://flagcdn.com/w160/gb.png',
    'eng': 'https://flagcdn.com/w160/gb.png',
    'south africa': 'https://flagcdn.com/w160/za.png',
    'sa': 'https://flagcdn.com/w160/za.png',
    'pakistan': 'https://flagcdn.com/w160/pk.png',
    'pak': 'https://flagcdn.com/w160/pk.png',
    'west indies': 'https://flagcdn.com/w160/jm.png',
    'wi': 'https://flagcdn.com/w160/jm.png',
    'sri lanka': 'https://flagcdn.com/w160/lk.png',
    'sl': 'https://flagcdn.com/w160/lk.png',
    'bangladesh': 'https://flagcdn.com/w160/bd.png',
    'ban': 'https://flagcdn.com/w160/bd.png',
    'afghanistan': 'https://flagcdn.com/w160/af.png',
    'afg': 'https://flagcdn.com/w160/af.png',
    'gujarat titans': 'https://flagcdn.com/w160/in.png',
    'chennai super kings': 'https://flagcdn.com/w160/in.png',
  };

  String _getEffectiveUrl() {
    final direct = logoUrl.trim();
    if (direct.isNotEmpty && !direct.contains('gb-eng.png')) {
      return direct;
    }

    if (teamName != null && teamName!.trim().isNotEmpty) {
      final key = teamName!.trim().toLowerCase();
      for (final entry in _knownTeamFlags.entries) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          return entry.value;
        }
      }
    }

    return '';
  }

  String _getTeamInitials() {
    if (teamName == null || teamName!.trim().isEmpty) return 'CR';
    final words = teamName!.trim().split(' ');
    if (words.length == 1) {
      final word = words.first;
      return word.length >= 3 ? word.substring(0, 3).toUpperCase() : word.toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _getEffectiveUrl();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF22242D),
        border: Border.all(
          color: const Color(0xFF383A48),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: effectiveUrl.isNotEmpty
            ? Image.network(
                effectiveUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return _buildFallbackInitials();
                },
                errorBuilder: (context, error, stackTrace) => _buildFallbackInitials(),
              )
            : _buildFallbackInitials(),
      ),
    );
  }

  Widget _buildFallbackInitials() {
    final initials = _getTeamInitials();

    return Container(
      color: const Color(0xFF252834),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_cricket,
            size: size * 0.7,
            color: AppColors.accentGreen.withValues(alpha: 0.2),
          ),
          Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
