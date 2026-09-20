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
    'england': 'https://flagcdn.com/w160/gb-eng.png',
    'eng': 'https://flagcdn.com/w160/gb-eng.png',
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
    'mumbai indians': 'https://flagcdn.com/w160/in.png',
    'mi': 'https://flagcdn.com/w160/in.png',
    'rcb': 'https://flagcdn.com/w160/in.png',
    'royal challengers': 'https://flagcdn.com/w160/in.png',
    'kolkata': 'https://flagcdn.com/w160/in.png',
    'kkr': 'https://flagcdn.com/w160/in.png',
    'punjab': 'https://flagcdn.com/w160/in.png',
    'rajasthan': 'https://flagcdn.com/w160/in.png',
    'hyderabad': 'https://flagcdn.com/w160/in.png',
    'srh': 'https://flagcdn.com/w160/in.png',
    'dc': 'https://flagcdn.com/w160/in.png',
    'delhi': 'https://flagcdn.com/w160/in.png',
    'zimbabwe': 'https://flagcdn.com/w160/zw.png',
    'zim': 'https://flagcdn.com/w160/zw.png',
    'ireland': 'https://flagcdn.com/w160/ie.png',
    'ire': 'https://flagcdn.com/w160/ie.png',
    'netherlands': 'https://flagcdn.com/w160/nl.png',
    'ned': 'https://flagcdn.com/w160/nl.png',
    'scotland': 'https://flagcdn.com/w160/gb-sct.png',
    'scot': 'https://flagcdn.com/w160/gb-sct.png',
  };

  String _getEffectiveUrl() {
    final direct = logoUrl.trim();
    // Use the direct URL if it's a valid non-empty http/https URL
    if (direct.isNotEmpty &&
        (direct.startsWith('http://') || direct.startsWith('https://'))) {
      return direct;
    }

    // Fall back to team name lookup
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
            ? _NetworkImageWithFade(
                url: effectiveUrl,
                size: size,
                fallback: _buildFallbackInitials(),
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

/// A stateful widget that loads a network image and fades it in once ready.
/// Shows a skeleton/shimmer while loading, and fallback on error.
class _NetworkImageWithFade extends StatefulWidget {
  final String url;
  final double size;
  final Widget fallback;

  const _NetworkImageWithFade({
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  State<_NetworkImageWithFade> createState() => _NetworkImageWithFadeState();
}

class _NetworkImageWithFadeState extends State<_NetworkImageWithFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  bool _loaded = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _resolveImage();
  }

  @override
  void didUpdateWidget(_NetworkImageWithFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cancelListeners();
      setState(() {
        _loaded = false;
        _error = false;
      });
      _controller.reset();
      _resolveImage();
    }
  }

  void _resolveImage() {
    final provider = NetworkImage(widget.url);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        if (!mounted) return;
        setState(() => _loaded = true);
        _controller.forward();
      },
      onError: (Object exception, StackTrace? stackTrace) {
        if (!mounted) return;
        setState(() => _error = true);
      },
    );
    _imageStream!.addListener(_listener!);
  }

  void _cancelListeners() {
    _imageStream?.removeListener(_listener!);
    _imageStream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _cancelListeners();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return widget.fallback;
    }

    if (!_loaded) {
      // Shimmer skeleton while loading
      return _ShimmerBox(size: widget.size);
    }

    return FadeTransition(
      opacity: _opacity,
      child: Image.network(
        widget.url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, _) => widget.fallback,
      ),
    );
  }
}

/// Animated shimmer placeholder shown while the logo image loads.
class _ShimmerBox extends StatefulWidget {
  final double size;
  const _ShimmerBox({required this.size});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.size,
        height: widget.size,
        color: Color.lerp(
          const Color(0xFF2A2D3A),
          const Color(0xFF363A4A),
          _anim.value,
        ),
      ),
    );
  }
}
