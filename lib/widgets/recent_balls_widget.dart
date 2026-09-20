import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Displays the last 6 balls of the current over inline on a match card.
/// For Live matches, always shows 6 slots — filled or empty dashes.
class RecentBallsWidget extends StatelessWidget {
  final List<String> balls;

  /// When true, always renders 6 slots even if [balls] is empty.
  /// Use this on Live match cards so the row is always visible.
  final bool showEmptySlots;

  const RecentBallsWidget({
    super.key,
    required this.balls,
    this.showEmptySlots = false,
  });

  // ── Color scheme for each ball type ──────────────────────────────────────

  static Color bgColor(String ball) {
    final b = ball.trim().toUpperCase();
    if (b == 'W') return const Color(0xFFD32F2F);
    if (b == '6') return const Color(0xFFE68A00);
    if (b == '4') return const Color(0xFF1B6B3A);
    if (b == 'WD') return const Color(0xFF5B4A8A);
    if (b == 'NB') return const Color(0xFF7A5C00);
    return const Color(0xFF2E3040);
  }

  static Color textColor(String ball) {
    return Colors.white;
  }

  static Color borderColor(String ball) {
    final b = ball.trim().toUpperCase();
    if (b == 'W') return const Color(0xFFEF5350);
    if (b == '6') return const Color(0xFFFFB300);
    if (b == '4') return const Color(0xFF2E9E5B);
    if (b == 'WD') return const Color(0xFF7C6CB0);
    if (b == 'NB') return const Color(0xFFA07B0A);
    return const Color(0xFF3E4155);
  }

  @override
  Widget build(BuildContext context) {
    if (balls.isEmpty && !showEmptySlots) return const SizedBox.shrink();

    // When 6 recentball is full, the leftmost ball remains in database
    // but not in visual, keeping the rightmost slot free for the next ball.
    final visualBalls = balls.length >= 6
        ? balls.sublist(balls.length - 5)
        : balls;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18191F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252630), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THIS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'OVER',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // 6 ball slots - evenly distributed across the entire middle space
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ballSize =
                    ((constraints.maxWidth - 20) / 6).clamp(24.0, 31.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) {
                    final hasBall = i < visualBalls.length;
                    return hasBall
                        ? _FilledBall(
                            ball: visualBalls[i],
                            size: ballSize,
                          )
                        : _EmptySlot(
                            isNext: i == visualBalls.length,
                            size: ballSize,
                          );
                  }),
                );
              },
            ),
          ),

          // Over total (run sum)
          if (visualBalls.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              height: 20,
              width: 1,
              color: const Color(0xFF282A36),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_overRuns(visualBalls)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'runs',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int _overRuns(List<String> bs) {
    int total = 0;
    for (final b in bs) {
      final clean = b.trim().toUpperCase();
      if (clean == 'W') continue;
      if (clean == 'WD' || clean == 'NB') {
        total += 1;
      } else {
        total += int.tryParse(clean) ?? 0;
      }
    }
    return total;
  }
}

// ── Filled ball circle ────────────────────────────────────────────────────────

class _FilledBall extends StatefulWidget {
  final String ball;
  final double size;
  const _FilledBall({required this.ball, this.size = 28.0});

  @override
  State<_FilledBall> createState() => _FilledBallState();
}

class _FilledBallState extends State<_FilledBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clean = widget.ball.trim().toUpperCase();
    final bg = RecentBallsWidget.bgColor(widget.ball);
    final border = RecentBallsWidget.borderColor(widget.ball);
    final isSmallText = clean.length > 1;
    final fontSize = isSmallText
        ? (widget.size * 0.32).clamp(7.5, 9.5)
        : (widget.size * 0.42).clamp(10.5, 13.0);

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          clean,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: isSmallText ? -0.5 : 0,
          ),
        ),
      ),
    );
  }
}

// ── Empty placeholder slot ────────────────────────────────────────────────────

class _EmptySlot extends StatefulWidget {
  /// When true this is the "next ball" slot — renders with a subtle pulse.
  final bool isNext;
  final double size;
  const _EmptySlot({required this.isNext, this.size = 28.0});

  @override
  State<_EmptySlot> createState() => _EmptySlotState();
}

class _EmptySlotState extends State<_EmptySlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _opacity = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isNext) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.isNext
        ? (widget.size * 0.24).clamp(5.0, 7.0)
        : (widget.size * 0.18).clamp(4.0, 6.0);

    if (widget.isNext) {
      return FadeTransition(
        opacity: _opacity,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF222430),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.75),
              width: 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.85),
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1C1D24),
        border: Border.all(color: const Color(0xFF2E3040), width: 1),
      ),
      alignment: Alignment.center,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF353749),
        ),
      ),
    );
  }
}
